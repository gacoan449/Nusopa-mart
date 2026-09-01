import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  final name = TextEditingController();
  bool loading = false;

  Future<void> register() async {
    if (email.text.trim().isEmpty || pass.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email harus diisi dan password minimal 6 karakter.')));
      return;
    }
    setState(() => loading = true);
    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email.text.trim(), password: pass.text);
      final displayName = name.text.trim();
      await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).set({
        'email': result.user!.email,
        'displayName': displayName,
        'role': 'BUYER',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('social_profiles').doc(result.user!.uid).set({
        'displayName': displayName,
        'photoUrl': '',
        'coverPhotoUrl': '',
        'bio': '',
        'rekberRating': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Daftar gagal')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Buat akun')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.storefront_rounded, size: 58, color: Color(0xFF126BFF)),
                const SizedBox(height: 14),
                const Text('Daftar Nusopa.Mart', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 24),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama')),
                TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password minimal 6 karakter')),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: loading ? null : register,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: Text(loading ? 'Membuat akun...' : 'DAFTAR SEKARANG'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    name.dispose();
    super.dispose();
  }
}
