import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_dashboard_screen.dart'; // Mengimpor halaman dashboard admin Anda
import 'bantuan_screen.dart';         // Mengimpor halaman pusat bantuan & chat AI

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Silakan ganti email di bawah ini dengan email akun admin rahasia Anda
  final String emailAdminRahasia = "admin.nusopamart@gmail.com";

  // Fungsi aktivasi toko instan untuk pembeli yang mau jadi seller
  void _aktivasiTokoSeller(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': 'seller',
        'kuota_tiket': 5, // Bonus awal 5 tiket jualan gratis
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toko berhasil aktif! Anda mendapatkan bonus 5 Tiket Jualan!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal aktivasi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Silakan login terlebih dahulu.')));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Gagal memuat profil database.'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String namaUser = userData['nama'] ?? 'Pengguna Gacoan';
          String emailUser = userData['email'] ?? '';
          String role = userData['role'] ?? 'buyer';
          int kuotaTiket = userData['kuota_tiket'] ?? 0;
          bool isSeller = (role == 'seller');

          return SingleChildScrollView(
            child: Column(
              children: [
                // ==========================================
                // 1. HEADER PROFIL MEWAH (WARNA BIRU PREMIUM)
                // ==========================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 50, 16, 25),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.blue.shade800, Colors.blue.shade600],
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      // Baris Atas: Foto Profil & Nama
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 29,
                              backgroundColor: Colors.blue.shade50,
                              child: const Icon(Icons.person, size: 40, color: Colors.blue),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  namaUser,
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),
                                // Badge Keanggotaan Shopee Style
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(51),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isSeller ? '✦ Mitra Seller' : '✦ Member Reguler',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Tombol Pengaturan di Pojok Kanan Atas Header
                          IconButton(
                            icon: const Icon(Icons.settings, color: Colors.white),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // 2. BLOK STATUS PESANAN SAYA (SHOPEE STYLE)
                // ==========================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          // Judul Riwayat
                          Row(
                            mainAxisAlignment: MainAxisAlignment.between,
                            children: [
                              const Text('Pesanan Saya (Belanja COD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Row(
                                children: [
                                  Text('Lihat Riwayat', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  Icon(Icons.chevron_right, color: Colors.grey.shade600, size: 16),
                                ],
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(),
                          ),
                          // Baris Tombol Menu Horizontal Status Pesanan
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatusIcon(Icons.wallet, 'Belum Bayar'),
                              _buildStatusIcon(Icons.archive_outlined, 'Dikemas'),
                              _buildStatusIcon(Icons.local_shipping_outlined, 'Dikirim'),
                              _buildStatusIcon(Icons.star_outline, 'Beri Nilai'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ==========================================
                // 3. BLOK OPERASIONAL KHUSUS SELLER / TOMBOL BUKA TOKO
                // ==========================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: isSeller
                      ? Card(
                          // JIKA AKUN SUDAH JADI SELLER
                          color: Colors.blue.shade50,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: Colors.blue.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.between,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.storefront, color: Colors.blue, size: 20),
                                        SizedBox(width: 8),
                                        Text('Menu Dashboard Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(6)),
