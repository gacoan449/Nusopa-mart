import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_dashboard_screen.dart'; 
import 'pesanan_screen.dart'; // Impor untuk menghubungkan operasional toko

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // PERBAIKAN 3: Email akun admin utama untuk membuka gerbang verifikasi tiket QRIS
  final String emailAdminRahasia = "admin.nusopamart@gmail.com";

  // Fungsi aktivasi toko instan dengan bonus 5 tiket awal
  void _bukaTokoSederhana(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': 'seller',
        'kuota_tiket': 5, 
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('Selamat! Toko Anda berhasil diaktifkan + Bonus 5 Tiket!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Gagal membuka toko: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login terlebih dahulu.', style: TextStyle(color: Colors.grey))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      // PERBAIKAN 2: AppBar diubah ke warna identitas Oranye Premium COD Nusopa
      appBar: AppBar(
        title: const Text('Akun & Kemitraan Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.orange.shade800, 
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () => _auth.signOut(),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data profil tidak ditemukan di database.'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String namaUser = userData['nama'] ?? 'Pengguna Baru';
          String emailUser = userData['email'] ?? '';
          String role = userData['role'] ?? 'buyer';
          int kuotaTiket = userData['kuota_tiket'] ?? 0;
          bool isSeller = (role == 'seller');
          
          // Deteksi hak akses admin melalui email atau field role
          bool isAdmin = (emailUser == emailAdminRahasia || role == 'admin');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. KARTU IDENTITAS PENGGUNA
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.orange.shade50,
                          child: Icon(Icons.person, size: 30, color: Colors.orange.shade800),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(namaUser, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isAdmin ? Colors.red.shade50 : (isSeller ? Colors.green.shade50 : Colors.grey.shade100),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isAdmin ? "✦ Akun Admin Utama" : (isSeller ? "✦ Mitra Seller Jualan" : "✦ Akun Pembeli Retail"),
                                  style: TextStyle(
                                    color: isAdmin ? Colors.red.shade800 : (isSeller ? Colors.green.shade800 : Colors.grey.shade600),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. KONDISI TAMPILAN KHUSUS SELLER (SUDAH BUKA TOKO)
                if (isSeller) ...[
                  Text(
                    'Manajemen Kuota Toko Anda', 
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                  ),
                  const SizedBox(height: 8),
                  
                  // KOTAK DOMPET TIKET JALANAN (Warna Oranye Senada Beranda)
                  Card(
                    elevation: 0,
                    color: Colors.orange.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.confirmation_number, color: Colors.white70, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Sisa Tiket Jualan Aktif',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$kuotaTiket Tiket',
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '*1 Tiket otomatis terpotong saat transaksi COD selesai. Isi ulang via QRIS Admin jika tiket mendekati angka 0.',
                            style: TextStyle(color: Colors.white60, fontSize: 10, height: 1.4),
                          ),
                          const SizedBox(height: 14),
                          
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.orange.shade900,
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              // Navigasi ke halaman BeliTiketScreen Anda
                            },
                            icon: const Icon(Icons.qr_code_scanner, size: 18),
                            label: const Text('BELI TIKET VIA QRIS ADMIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Operasional Toko', 
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: Colors.grey.shade200)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.add_photo_alternate, color: Colors.orange.shade800, size: 20),
                          title: const Text('Tambah Produk Baru', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          subtitle: const Text('Upload gambar dan set harga COD', style: TextStyle(fontSize: 11)),
