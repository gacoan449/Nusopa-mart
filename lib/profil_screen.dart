import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_dashboard_screen.dart'; 
import 'bantuan_screen.dart';         

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Email akun admin utama untuk verifikasi tiket QRIS
  final String emailAdminRahasia = "admin.nusopamart@gmail.com";

  // Fungsi aktivasi toko instan dengan bonus 5 tiket awal
  void _aktivasiTokoSeller(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': 'seller',
        'kuota_tiket': 5, 
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('Toko berhasil aktif! Anda mendapatkan bonus 5 Tiket Jualan!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Gagal aktivasi: $e')));
      }
    }
  }

  // Fungsi keluar aplikasi dengan aman
  void _keluarAkun() async {
    await _auth.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil keluar dari akun.')),
      );
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Gagal memuat profil database.'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String namaUser = userData['nama'] ?? 'Pengguna Nusopa';
          String emailUser = userData['email'] ?? '';
          String role = userData['role'] ?? 'buyer';
          int kuotaTiket = userData['kuota_tiket'] ?? 0;
          bool isSeller = (role == 'seller');
          
          // Cek hak akses admin melalui email atau field role
          bool isAdmin = (emailUser == emailAdminRahasia || role == 'admin');

          return SingleChildScrollView(
            child: Column(
              children: [
                // HEADER PROFIL GRADASI ORANYE NUSOPA PREMIUM
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 50, 16, 25),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.orange.shade900, Colors.orange.shade700],
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.orange.shade50,
                          child: Icon(Icons.person, size: 35, color: Colors.orange.shade800),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              namaUser,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isAdmin ? '✦ Akun Admin' : (isSeller ? '✦ Mitra Seller' : '✦ Member Reguler'),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white, size: 20),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                // BLOK STATUS PESANAN PEMBELI
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: Colors.grey.shade200)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.between,
                            children: [
                              const Text('Pesanan Saya (Belanja COD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Row(
                                children: [
                                  Text('Riwayat Belanja', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                  Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 14),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatusIcon(Icons.receipt_long_outlined, 'Belum Kirim'),
                              _buildStatusIcon(Icons.local_shipping_outlined, 'Dikirim'),
                              _buildStatusIcon(Icons.check_box_outlined, 'Selesai'),
                              _buildStatusIcon(Icons.star_outline, 'Ulasan'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // PILIHAN SELLER (DOMPET TIKET JUALAN)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: isSeller
                      ? Card(
                          elevation: 0,
                          color: Colors.orange.shade50,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: Colors.orange.shade200),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.between,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.storefront, color: Colors.orange.shade900, size: 18),
                                        const SizedBox(width: 8),
                                        Text('Menu Manajemen Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange.shade900)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.emerald.shade700, borderRadius: BorderRadius.circular(4)),
                                      child: Text(
                                        'Saldo: $kuotaTiket Tiket',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
