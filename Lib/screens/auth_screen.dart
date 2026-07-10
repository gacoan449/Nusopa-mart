import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();

  bool isLoginMode = true; // true = Login, false = Daftar Akun Baru
  bool isLoading = false;

  // Fungsi Proses Autentikasi
  void _submitAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      if (isLoginMode) {
        // 1. PROSES LOGIN
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // 2. PROSES DAFTAR AKUN BARU
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Buat Data Profil Pengguna di Firestore secara Otomatis
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'nama': _namaController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'buyer', // Default status awal adalah pembeli biasa
          'kuota_tiket': 0, // Kuota tiket jualan awal kosong
          'buat_pada': Timestamp.now(),
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isLoginMode ? 'Berhasil Masuk!' : 'Pendaftaran Berhasil!')),
        );
        // Di sini nanti arahkan ke halaman Utama / MainNavigation Anda
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Terjadi kesalahan. Silakan coba lagi.";
      if (e.code == 'user-not-found') errorMessage = 'Email tidak terdaftar.';
      if (e.code == 'wrong-password') errorMessage = 'Password salah.';
      if (e.code == 'email-already-in-use') errorMessage = 'Email sudah digunakan akun lain.';
      if (e.code == 'weak-password') errorMessage = 'Password terlalu lemah (minimal 6 karakter).';
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade700, // Warna Biru Premium DesaPay
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // LOGO DAN CIRI KHAS APLIKASI
                    Icon(Icons.local_mall, size: 60, color: Colors.blue.shade700),
                    const SizedBox(height: 10),
                    Text(
                      isLoginMode ? 'Selamat Datang Kembali' : 'Buat Akun Baru',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    ),
                    const SizedBox(height: 20),

                    // INPUT NAMA (Hanya Muncul Saat Daftar Akun Baru)
                    if (!isLoginMode) ...[
                      TextFormField(
                        controller: _namaController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 15),
                    ],

                    // INPUT EMAIL
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value!.isEmpty || !value.contains('@')) ? 'Masukkan email yang valid' : null,
                    ),
                    const SizedBox(height: 15),

                    // INPUT PASSWORD
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Kata Sandi (Password)',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.length < 6 ? 'Password minimal 6 karakter' : null,
                    ),
                    const SizedBox(height: 25),

                    // TOMBOL UTAMA
                    isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _submitAuth,
                            child: Text(
                              isLoginMode ? 'MASUK' : 'DAFTAR SEKARANG',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                    const SizedBox(height: 15),

                    // TOMBOL SWITCH MODE (LOGIN <-> DAFTAR)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isLoginMode = !isLoginMode;
                        });
                      },
                      child: Text(
                        isLoginMode ? 'Belum punya akun? Daftar di sini' : 'Sudah punya akun? Masuk di sini',
                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
