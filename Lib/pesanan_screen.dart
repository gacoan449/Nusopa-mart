import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class PesananScreen extends StatefulWidget {
  const PesananScreen({super.key});

  @override
  State<PesananScreen> createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Fungsi otomatis mengarahkan pembeli ke situs cekresi eksternal gratis
  void _lacakPaketWeb(String resi) async {
    final Uri url = Uri.parse('https://cekresi.com');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka browser pelacakan.')),
      );
    }
  }

  // SISI SELLER: Menginput nomor resi paket manual ke Firestore
  void _inputResiManual(String orderId, String kurir, String resi) async {
    if (kurir.isEmpty || resi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kurir dan Nomor Resi wajib diisi!')),
      );
      return;
    }
    await _firestore.collection('orders').doc(orderId).update({
      'status': 'dikirim',
      'kurir': kurir,
      'no_resi': resi,
    });
    if (mounted) Navigator.pop(context);
  }

  // SISI PEMBELI: Konfirmasi Terima Barang & Potong Otomatis 1 Tiket Jualan Seller
  void _konfirmasiPesananDiterima({
    required String orderId,
    required String sellerId,
  }) async {
    try {
      // Jalankan Firestore Transaction agar perhitungan kuota tiket aman tanpa bug (Race Condition)
      await _firestore.runTransaction((transaction) async {
        DocumentReference orderRef = _firestore.collection('orders').doc(orderId);
        DocumentReference sellerRef = _firestore.collection('users').doc(sellerId);

        DocumentSnapshot sellerSnapshot = await transaction.get(sellerRef);
        int kuotaSekarang = sellerSnapshot['kuota_tiket'] ?? 0;

        // Hitung sisa kuota tiket seller dikurangi 1
        int kuotaBaru = kuotaSekarang - 1;
        if (kuotaBaru < 0) kuotaBaru = 0; // Mengamankan agar tiket tidak minus

        // Update database sekaligus secara atomik
        transaction.update(orderRef, {'status': 'selesai'});
        transaction.update(sellerRef, {'kuota_tiket': kuotaBaru});
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi Selesai! Terima kasih telah mengonfirmasi.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal konfirmasi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Silakan login.')));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Status Transaksi'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(text: 'Belanjaan Saya'),
            Tab(text: 'Pesanan Masuk Toko'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBuyerOrderList(user.uid),  // Tampilan Sisi Pembeli
          _buildSellerOrderList(user.uid), // Tampilan Sisi Penjual
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET SISI PEMBELI (BELANJAAN SAYA)
  // ==========================================
  Widget _buildBuyerOrderList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('orders').where('buyer_id', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Belum ada riwayat pembelian barang.'));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var orderId = docs[index].id;
            var data = docs[index].data() as Map<String, dynamic>;

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Image.network(data['foto_url'] ?? '', width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(data['nama_produk'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('Total COD: Rp ${data['total_harga']} (${data['jumlah_beli']} barang)'),
                      trailing: Text(
                        data['status'].toString().toUpperCase(),
                        style: TextStyle(color: data['status'] == 'selesai' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const Divider(),
                    if (data['status'] == 'perlu_dikirim')
                      const Text('💬 Menunggu penjual menyerahkan paket ke kurir.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey)),
                    if (data['status'] == 'dikirim') ...[
                      Text('📦 Kurir: ${data['kurir']} (${data['no_resi']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, foregroundColor: Colors.blue.shade800, dense: true),
                            onPressed: () => _lacakPaketWeb(data['no_resi']),
                            icon: const Icon(Icons.search, size: 14),
                            label: const Text('Lacak Paket'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, dense: true),
                            onPressed: () => _konfirmasiPesananDiterima(orderId: orderId, sellerId: data['seller_id']),
                            child: const Text('Pesanan Diterima & Bayar COD'),
                          ),
                        ],
                      )
                    ],
                    if (data['status'] == 'selesai')
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 5),
                          Text('Barang telah sampai dan sukses terbayar.', style: TextStyle(color: Colors.green, fontSize: 12)),
                        ],
                      )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // WIDGET SISI PENJUAL (PESANAN MASUK TOKO)
  // ==========================================
  Widget _buildSellerOrderList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('orders').where('seller_id', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Belum ada pesanan masuk dari pembeli.'));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var orderId = docs[index].id;
            var data = docs[index].data() as Map<String, dynamic>;
            final TextEditingController kurirCont = TextEditingController();
            final TextEditingController resiCont = TextEditingController();

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📍 Alamat Kirim: ${data['alamat_kirim']}', style: const TextStyle(fontSize: 12, color: Colors.black84, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 5),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Image.network(data['foto_url'] ?? '', width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(data['nama_produk'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('Harga Barang: Rp ${data['total_harga']} (${data['jumlah_beli']} Pcs)'),
                    ),
