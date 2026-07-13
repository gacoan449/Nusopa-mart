import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _hpController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _prosesLoginFirebase() async {
    if (_hpController.text.isEmpty || _passController.text.isEmpty) {
      _notif("Harap isi semua kolom!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Mencari data akun di tabel 'users' cloud Firebase berdasarkan nomor HP
      var query = await FirebaseFirestore.instance
          .collection('users')
          .where('noHp', isEqualTo: _hpController.text.trim())
          .get();

      if (query.docs.isEmpty) {
        _notif("Nomor HP tidak terdaftar!");
        return;
      }

      var userData = query.docs.first.data();

      // Validasi password kecocokan secara lokal aman
      if (userData['password'] == _passController.text) {
        _notif("Selamat Datang, ${userData['nama']}!");
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        _notif("Password salah!");
      }
    } catch (e) {
      _notif("Gagal terhubung ke Firebase Cloud: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _notif(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag, size: 80, color: Color(0xFFFF5722)),
              const SizedBox(height: 16),
              Text('Nusopa.Mart', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFFFF5722))),
              Text('Sederhana tapi Mewah', style: GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 40),
              TextField(
                controller: _hpController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Nomor HP Toko / Pembeli',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _prosesLoginFirebase,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Masuk Aplikasi (Firebase)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
