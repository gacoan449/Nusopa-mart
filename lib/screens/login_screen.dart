import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
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

  // ISI ALAMAT IP LAPTOP / DOMAIN VPS ANDA DI SINI
  // Jika pakai Emulator Android bawaan, ganti localhost menjadi 10.0.2.2
  final String _apiUrl = "http://10.0.2";

  Future<void> _prosesLogin() async {
    if (_hpController.text.isEmpty || _passController.text.isEmpty) {
      _tampilkanPesan("Harap isi semua kolom!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final respon = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "noHp": _hpController.text,
          "password": _passController.text,
        }),
      );

      final data = jsonDecode(respon.body);

      if (respon.statusCode == 200 && data['success'] == true) {
        _tampilkanPesan("Selamat Datang, ${data['user']['nama']}!");
        
        // Berhasil masuk, arahkan langsung ke HomeScreen utama
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        _tampilkanPesan(data['message'] ?? "Login gagal!");
      }
    } catch (e) {
      _tampilkanPesan("Gagal terhubung ke server backend: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _tampilkanPesan(String pesan) {
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
              
              // Input No HP
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
              
              // Input Password
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
              
              // Tombol Login Kapsul Mewah
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  onPressed: _isLoading ? null : _prosesLogin,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Masuk Aplikasi', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
