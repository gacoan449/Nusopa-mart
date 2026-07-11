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
  final TextEditingController _namaTokoController = TextEditingController(); // Khusus Seller

  bool isLoginMode = true; 
  bool isLoading = false;
  bool _sembunyikanPassword = true; // Fitur intip password
  String _roleDipilih = 'buyer'; // Pilihan role dinamis saat daftar: 'buyer' atau 'seller'

  // PERBAIKAN 2: Cegah kebocoran RAM HP (Memory Leak Protection)
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

        // PERBAIKAN 3: Menyimpan struktur data sesuai role pilihan user
        Map<String, dynamic> dataUser = {
          'uid': userCredential.user!.uid,
          'nama': _namaController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _roleDipilih,
          'buat_pada': Timestamp.now(),
        };

        if (_roleDipilih == 'seller') {
          dataUser['nama_toko'] = _namaTokoController.text.trim();
          dataUser['kuota_tiket'] = 0; // Saldo tiket awal jualan
          dataUser['kota_seller'] = 'Belum diatur'; // Nanti diisi di profil
        }

        await _firestore.collection('users').doc(userCredential.user!.uid).set(dataUser);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.emerald.shade700,
            content: Text(isLoginMode ? 'Selamat Datang Kembali!' : 'Pendaftaran Akun Sukses!'),
          ),
        );
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainNavigation()));
      }
    } on FirebaseAuthException catch (e) {
      // PERBAIKAN 1: Menangani standarisasi kode eror Firebase Auth terbaru (invalid-credential)
      String errorMessage = "Terjadi kesalahan sistem. Coba beberapa saat lagi.";
      
      if (e.code == 'invalid-credential') {
        errorMessage = 'Email atau kata sandi yang Anda masukkan salah.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email ini sudah terdaftar. Silakan login.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Kata sandi terlalu lemah (Minimal gunakan 6 karakter).';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'Akun Anda telah dinonaktifkan oleh admin.';
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
      // PERBAIKAN 4: Gradasi warna latar belakang premium agar visual mewah ala Shopee
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade800, Colors.orange.shade600], // Oranye khas COD Nusopa
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // LOGO UTAMA APLIKASI
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
                      Text(
                        isLoginMode ? 'Silakan masuk ke akun Anda' : 'Mulai belanja & jualan sistem COD',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // INPUT NAMA (Hanya Muncul Saat Daftar Akun Baru)
                      if (!isLoginMode) ...[
                        TextFormField(
                          controller: _namaController,
                          decoration: InputDecoration(
                            labelText: 'Nama Lengkap',
                            prefixIcon: const Icon(Icons.person_outline, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          validator: (value) => value!.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 16),

                        // SELEKTOR PILIHAN ROLE (BUYER / SELLER) YANG INTERAKTIF
                        Row(
                          children: [
                            const Text('Daftar Sebagai: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Pembeli'),
                                selected: _roleDipilih == 'buyer',
                                onSelected: (selected) {
                                  if (selected) setState(() => _roleDipilih = 'buyer');
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Penjual'),
                                selected: _roleDipilih == 'seller',
                                onSelected: (selected) {
                                  if (selected) setState(() => _roleDipilih = 'seller');
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // INPUT NAMA TOKO (Hanya muncul jika mendaftar sebagai SELLER)
                        if (_roleDipilih == 'seller') ...[
                          TextFormField(
                            controller: _namaTokoController,
                            decoration: InputDecoration(
                              labelText: 'Nama Toko Jualan Anda',
                              prefixIcon: const Icon(Icons.storefront, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            validator: (value) => value!.trim().isEmpty ? 'Nama toko wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],

                      // INPUT EMAIL
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Alamat Email',
                          prefixIcon: const Icon(Icons.email_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        validator: (value) => (value!.isEmpty || !value.contains('@')) ? 'Masukkan email yang valid' : null,
                      ),
                      const SizedBox(height: 16),

                      // INPUT PASSWORD WITH EYE TOGGLE ICONS
                      TextFormField(
                        controller: _passwordController,
