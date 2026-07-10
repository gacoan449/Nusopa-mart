import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fungsi untuk mengubah status pembeli biasa menjadi Seller di Firebase
  void _bukaTokoSederhana(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': 'seller',
        'kuota_tiket': 5, // Bonus 5 tiket gratis pertama untuk pemicu seller baru!
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selamat! Toko Anda berhasil diaktifkan + Bonus 5 Tiket!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka toko: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    // Jika user belum login di Firebase Auth, tampilkan pesan peringatan
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login terlebih dahulu di AuthScreen.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Akun & Kemitraan Toko'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Tombol Keluar Log Out Sederhana
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _auth.signOut(),
          )
        ],
      ),
      // Menggunakan StreamBuilder agar data Profil & TIKET tersinkron Realtime dari Firestore
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data profil tidak ditemukan di database.'));
          }

          // Ambil data dari dokumen Firestore
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String namaUser = userData['nama'] ?? 'Pengguna Baru';
          String role = userData['role'] ?? 'buyer';
          int kuotaTiket = userData['kuota_tiket'] ?? 0;
          bool isSeller = (role == 'seller');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. KARTU IDENTITAS PENGGUNA
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue.shade50,
                          child: Icon(Icons.person, size: 35, color: Colors.blue.shade700),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(namaUser, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                isSeller ? "Mitra Seller Jualan" : "Akun Pembeli Retail",
                                style: TextStyle(
                                  color: isSeller ? Colors.green.shade700 : Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // 2. KONDISI TAMPILAN KHUSUS SELLER (SUDAH BUKA TOKO)
                if (isSeller) ...[
                  Text(
                    'Manajemen Kuota Toko Anda', 
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                  ),
                  const SizedBox(height: 10),
                  
                  // KOTAK DOMPET TIKET JALANAN (MENIRU DESAIN BERSIH DESAPAY)
                  Card(
                    color: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.confirmation_number, color: Colors.white70, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Sisa Tiket Jualan Aktif',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$kuotaTiket Tiket',
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '*1 Tiket otomatis terpotong saat transaksi COD selesai. Isi ulang via QRIS Admin jika tiket mendekati angka 0.',
                            style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.4),
                          ),
                          const SizedBox(height: 20),
                          
                          // TOMBOL MENU ISI TIKET MANUAL VIA QRIS
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              // TODO: Navigasi ke halaman BeliTiketScreen() yang kemarin kita rancang
                            },
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('BELI TIKET VIA QRIS ADMIN', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // MENU NAVIGASI KELOLA DAGANGAN SELLER
                  Text(
                    'Operasional Toko', 
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                  ),
                  const SizedBox(height: 5),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.add_photo_alternate, color: Colors.orange),
                          title: const Text('Tambah Produk Baru'),
                          subtitle: const Text('Upload gambar dan set harga COD'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () {
                            // TODO: Arahkan ke Form Tambah Produk
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.local_shipping, color: Colors.blue),
                          title: const Text('Pesanan Masuk & Input Resi'),
                          subtitle: const Text('Kelola pengiriman kurir manual'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () {
                            // TODO: Arahkan ke Daftar Pesanan Toko
                          },
                        ),
                      ],
                    ),
                  ),

                // 3. KONDISI TAMPILAN KETIKA MASIH JADI PEMBELI BIASA
                ] else ...[
                  Text(
                    'Program Kemitraan Seller', 
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    color: Colors.orange.shade50,
