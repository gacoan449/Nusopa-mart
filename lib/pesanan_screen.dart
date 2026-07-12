import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _lacakPaketWeb(String resi) async {
    final Uri url = Uri.parse('https://cekresi.com');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka browser pelacakan.')),
        );
      }
    }
  }

  // SISI SELLER: Input resi eksternal aman via Dialog Pop-up
  void _inputResiManual(String orderId, String kurir, String resi) async {
    if (kurir.trim().isEmpty || resi.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text('Kurir dan Nomor Resi wajib diisi!')),
      );
      return;
    }
    
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'dikirim',
        'kurir': kurir.trim(),
        'no_resi': resi.trim(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('Resi berhasil diperbarui! Paket dalam pengiriman.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal input resi: $e')));
      }
    }
  }

  // Menghapus duplikasi pemotongan tiket
  void _konfirmasiPesananDiterima({required String orderId}) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'selesai',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('Transaksi Selesai! Terima kasih telah mengonfirmasi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal konfirmasi: $e')));
      }
    }
  }

  // Dialog interaktif khusus untuk input resi
  void _bukaDialogInputResi(BuildContext context, String orderId) {
    final TextEditingController kurirCont = TextEditingController();
    final TextEditingController resiCont = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Input Resi Kurir Manual', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: kurirCont,
              decoration: const InputDecoration(labelText: 'Nama Kurir / Gerai (Misal: J&T, JNE)', labelStyle: TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: resiCont,
              decoration: const InputDecoration(labelText: 'Nomor Resi / Bukti Nota Fisik', labelStyle: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              kurirCont.dispose();
              resiCont.dispose();
              Navigator.pop(context);
            },
            child: const Text('BATAL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
            onPressed: () {
              _inputResiManual(orderId, kurirCont.text, resiCont.text);
              kurirCont.dispose();
              resiCont.dispose();
              Navigator.pop(context);
            },
            child: const Text('KIRIM RESI'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Silakan login.')));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Status Transaksi COD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Belanjaan Saya'),
            Tab(text: 'Pesanan Masuk Toko'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBuyerOrderList(user.uid),  
          _buildSellerOrderList(user.uid), 
        ],
      ),
    );
  }

  Widget _buildBuyerOrderList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('orders').where('buyer_id', isEqualTo: uid).orderBy('dibuat_pada', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Eror: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.orange));
        
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Belum ada riwayat pembelian barang.', style: TextStyle(color: Colors.grey, fontSize: 13)));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var orderId = docs[index].id;
            var data = docs[index].data() as Map<String, dynamic>;

            return Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: Colors.grey.shade200)),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.between,
                      children: [
                        Text('📦 ID: ${orderId.substring(0, min(8, orderId.length))}', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: data['status'] == 'selesai' ? Colors.green.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            data['status'].toString().toUpperCase(),
                            style: TextStyle(color: data['status'] == 'selesai' ? Colors.green : Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            data['foto_url'] ?? '', width: 55, height: 55, fit: BoxFit.cover,
                            errorBuilder: (context, e, s) => Container(width: 55, height: 55, color: Colors.grey.shade100, child: const Icon(Icons.broken_image, size: 20)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['nama_produk'] ?? 'Produk COD', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('Total COD: Rp ${data['total_harga']} (${data['jumlah_beli']} Pcs)', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    if (data['status'] == 'perlu_dikirim')
                      const Text('💬 Menunggu penjual pergi ke gerai kurir untuk kirim barang.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: Colors.grey)),
                    if (data['status'] == 'dikirim') ...[
