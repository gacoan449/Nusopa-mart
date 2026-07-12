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
  final TextEditingController _namaTokoController = TextEditingController();

  bool isLoginMode = true; 
  bool isLoading = false;
  bool _sembunyikanPassword = true; 
  String _roleDipilih = 'buyer'; 

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _namaController.dispose();
    _namaTokoController.dispose();
    super.dispose();
  }

  void _submitAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      if (isLoginMode) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        Map<String, dynamic> dataUser = {
          'uid': userCredential.user!.uid,
          'nama': _namaController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _roleDipilih,
          'buat_pada': Timestamp.now(),
        };

        if (_roleDipilih == 'seller') {
          dataUser['nama_toko'] = _namaTokoController.text.trim();
          dataUser['kuota_tiket'] = 0; 
          dataUser['kota_seller'] = 'Belum diatur'; 
        }

        await _firestore.collection('users').doc(userCredential.user!.uid).set(dataUser);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Terjadi kesalahan sistem. Coba beberapa saat lagi.";
      if (e.code == 'invalid-credential') {
        errorMessage = 'Email atau kata sandi yang Anda masukkan salah.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email ini sudah terdaftar. Silakan login.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Kata sandi terlalu lemah (Minimal gunakan 6 karakter).';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red.shade800, content: Text(errorMessage)),
        );
      }
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade800, Colors.orange.shade600],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.orange.shade50,
                        child: Icon(Icons.local_mall, size: 35, color: Colors.orange.shade800),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isLoginMode ? 'Masuk ke Nusopa' : 'Gabung Mitra Nusopa',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Alamat Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty || !value.contains('@')) {
                            return 'Silakan masukkan email yang valid.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _sembunyikanPassword,
                        decoration: InputDecoration(
                          labelText: 'Kata Sandi',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_sembunyikanPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _sembunyikanPassword = !_sembunyikanPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 6) {
                            return 'Kata sandi minimal 6 karakter.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _submitAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade800,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 45),
                              ),
                              child: Text(isLoginMode ? 'Masuk' : 'Daftar'),
                            ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isLoginMode = !isLoginMode;
                          });
                        },
                        child: Text(
                          isLoginMode ? 'Belum punya akun? Daftar di sini' : 'Sudah punya akun? Masuk',
                          style: TextStyle(color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
