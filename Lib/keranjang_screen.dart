import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KeranjangScreen extends StatefulWidget {
  const KeranjangScreen({super.key});

  @override
  State<KeranjangScreen> createState() => _KeranjangScreenState();
}

class _KeranjangScreenState extends State<KeranjangScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _alamatController = TextEditingController();

  // Fungsi untuk mengubah jumlah pesanan barang di dalam keranjang
  void _ubahJumlahBarang(String cartId, int jumlahBaru) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (jumlahBaru <= 0) {
      // Jika jumlahnya 0, hapus barang dari keranjang
      await _firestore.collection('users').doc(user.uid).collection('cart').doc(cartId).delete();
    } else {
      // Jika tidak, update jumlahnya
      await _firestore.collection('users').doc(user.uid).collection('cart').doc(cartId).update({
        'jumlah': jumlahBaru,
      });
    }
  }

  // Fungsi sakral untuk checkout pesanan COD manual
  void _prosesCheckoutCOD(List<QueryDocumentSnapshot> cartItems, int totalBayar) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_alamatController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi alamat lengkap pengiriman untuk kurir COD!')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Loop semua barang yang ada di keranjang untuk dipindahkan ke tabel 'orders'
      for (var item in cartItems) {
        var data = item.data() as Map<String, dynamic>;

        await _firestore.collection('orders').add({
          'buyer_id': user.uid,
          'seller_id': data['seller_id'],
          'product_id': data['product_id'],
          'nama_produk': data['nama_produk'],
          'foto_url': data['foto_url'],
          'harga_satuan': data['harga'],
          'jumlah_beli': data['jumlah'],
          'total_harga': data['harga'] * data['jumlah'],
          'alamat_kirim': _alamatController.text.trim(),
          'status': 'perlu_dikirim', // Status awal pesanan COD
          'no_resi': '',
          'kurir': '',
          'dibuat_pada': Timestamp.now(),
        });

        // Hapus barang dari keranjang setelah berhasil dipesan
        await _firestore.collection('users').doc(user.uid).collection('cart').doc(item.id).delete();
      }

      if (mounted) {
        Navigator.pop(context); // Tutup loading dialog
        _alamatController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan COD Berhasil Dibuat! Penjual akan segera memproses barang Anda.')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal checkout: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Silakan login terlebih dahulu.')));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Keranjang Belanja (COD)'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').doc(user.uid).collection('cart').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('Keranjang belanja Anda masih kosong.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          var cartDocs = snapshot.data!.docs;
          int totalHargaSemua = 0;

          // Menghitung total harga belanjaan secara otomatis
          for (var doc in cartDocs) {
            var data = doc.data() as Map<String, dynamic>;
            int harga = data['harga'] ?? 0;
            int jumlah = data['jumlah'] ?? 1;
            totalHargaSemua += (harga * jumlah);
          }

          return Column(
            children: [
              // DAFTAR BARANG DI KERANJANG
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: cartDocs.length,
                  itemBuilder: (context, index) {
                    var cartId = cartDocs[index].id;
                    var data = cartDocs[index].data() as Map<String, dynamic>;

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.bottom(10),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            // Gambar Produk
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                data['foto_url'] ?? '',
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 70),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Info teks nama dan harga
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['nama_produk'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Rp ${data['harga']}',
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            // Pengatur Jumlah Beli (Plus / Minus)
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.blue),
                                  onPressed: () => _ubahJumlahBarang(cartId, data['jumlah'] - 1),
                                ),
                                Text('${data['jumlah']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                                  onPressed: () => _ubahJumlahBarang(cartId, data['jumlah'] + 1),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // FORM PENGISIAN ALAMAT & TOMBOL CHECKOUT (DITARUH DI BAWAH KAKU)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Form Alamat Rumah
                    TextField(
                      controller: _alamatController,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Lengkap Pengiriman COD',
                        hintText: 'Nama Jalan, No. Rumah, RT/RW, Kecamatan',
                        prefixIcon: Icon(Icons.location_on, color: Colors.red),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Ringkasan Pembayaran Pembeli
                    Row(
                      mainAxisAlignment: MainAxisAlignment.between,
                      children: [
                        const Text('Metode Pembayaran:', style: TextStyle(fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
