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

  // PERBAIKAN 2: Proteksi RAM ponsel agar aplikasi tidak lemot (Memory Leak Fix)
  @override
  void dispose() {
    _alamatController.dispose();
    super.dispose();
  }

  void _ubahJumlahBarang(String cartId, int jumlahBaru) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      if (jumlahBaru <= 0) {
        await _firestore.collection('users').doc(user.uid).collection('cart').doc(cartId).delete();
      } else {
        await _firestore.collection('users').doc(user.uid).collection('cart').doc(cartId).update({
          'jumlah': jumlahBaru,
        });
      }
    } catch (e) {
      debugPrint("Gagal mengubah jumlah barang: $e");
    }
  }

  // PERBAIKAN 1 & 3: Checkout menggunakan BATCH & Otomatis Memotong Kuota Tiket Penjual
  void _prosesCheckoutCOD(List<QueryDocumentSnapshot> cartItems) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_alamatController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Mohon isi alamat lengkap pengiriman untuk kurir COD!'),
        ),
      );
      return;
    }

    // Tampilkan loading dialog modern
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    try {
      // Inisialisasi Firestore Batch (Unggah banyak data sekaligus dalam 1 detik)
      WriteBatch batch = _firestore.batch();

      for (var item in cartItems) {
        var data = item.data() as Map<String, dynamic>;
        String sellerId = data['seller_id'] ?? '';

        // Dokumen pesanan baru
        DocumentReference orderRef = _firestore.collection('orders').doc();
        
        batch.set(orderRef, {
          'buyer_id': user.uid,
          'seller_id': sellerId,
          'product_id': data['product_id'],
          'nama_produk': data['nama_produk'],
          'foto_url': data['foto_url'],
          'harga_satuan': data['harga'],
          'jumlah_beli': data['jumlah'],
          'total_harga': (data['harga'] ?? 0) * (data['jumlah'] ?? 1),
          'alamat_kirim': _alamatController.text.trim(),
          'status': 'perlu_dikirim', 
          'no_resi': '',
          'bukti_resi_foto': '', // Untuk fitur foto struk manual penjual nanti
          'dibuat_pada': Timestamp.now(),
        });

        // ALGORITMA CORE UTAMA ANDA: Kurangi kuota tiket penjual sebanyak 1 poin per orderan
        if (sellerId.isNotEmpty) {
          DocumentReference sellerRef = _firestore.collection('users').doc(sellerId);
          batch.update(sellerRef, {
            'kuota_tiket': FieldValue.increment(-1), // Mengurangi saldo tiket otomatis di Firebase
          });
        }

        // Hapus item dari dokumen keranjang pembeli
        DocumentReference cartRef = _firestore.collection('users').doc(user.uid).collection('cart').doc(item.id);
        batch.delete(cartRef);
      }

      // Eksekusi seluruh operasi batch secara bersamaan
      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Tutup loading dialog
        _alamatController.clear();
        
        // Dialog Sukses Kreatif
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            title: const Text('Sukses!', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Pesanan COD Berhasil Dibuat!\nSistem telah memotong kuota tiket penjual secara otomatis.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Kembali ke halaman utama
                },
                child: const Text('OK', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Gagal checkout: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login terlebih dahulu.', style: TextStyle(color: Colors.grey))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Keranjang Belanja (COD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.orange.shade800, // PERBAIKAN 4: Tema warna diselaraskan oranye
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').doc(user.uid).collection('cart').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined, size: 55, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Keranjang belanja Anda masih kosong.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            );
          }

          var cartDocs = snapshot.data!.docs;
          int totalHargaSemua = 0;

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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  itemCount: cartDocs.length,
                  itemBuilder: (context, index) {
                    var cartId = cartDocs[index].id;
                    var data = cartDocs[index].data() as Map<String, dynamic>;

                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                data['foto_url'] ?? '',
                                width: 65,
                                height: 65,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 65, height: 65, color: Colors.grey.shade100,
                                  child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['nama_produk'] ?? 'Produk COD',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp $harga',
                                    style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline, color: Colors.orange.shade800, size: 20),
                                  onPressed: () => _ubahJumlahBarang(cartId, (data['jumlah'] ?? 1) - 1),
                                ),
