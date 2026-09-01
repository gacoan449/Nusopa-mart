import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_gate.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _adminEmail = 'admin@desapay.local';
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool hide = true;

  Future<void> login() async {
    final inputEmail = email.text.trim().toLowerCase();
    if (inputEmail.isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan email dan password.')));
      return;
    }
    setState(() => loading = true);
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(email: inputEmail, password: password.text);
      final user = result.user;
      if (user == null) throw StateError('Firebase tidak mengembalikan akun pengguna.');

      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final profile = await ref.get();

      if (!profile.exists) {
        if (inputEmail == _adminEmail) {
          await FirebaseAuth.instance.signOut();
          throw StateError('Akun admin berhasil ditemukan di Firebase Authentication, tetapi role ADMIN belum berada pada dokumen users/' + user.uid + '. Jangan gunakan ID email atau ID acak sebagai ID dokumen.');
        }
        await ref.set({
          'uid': user.uid,
          'email': user.email,
          'role': 'BUYER',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (_) => false,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Login gagal.')));
    } on FirebaseException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profil akun gagal diakses: ' + (error.message ?? error.code))));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF3F7FF),
    body: Stack(children: [
      const Positioned(top: -80, right: -40, child: _Glow()),
      SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .94),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: .12), blurRadius: 35)],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Icon(Icons.storefront_rounded, size: 66, color: Color(0xFF126BFF)),
                  const SizedBox(height: 14),
                  const Text('Nusopa.Mart', textAlign: TextAlign.center, style: TextStyle(fontSize: 31, fontWeight: FontWeight.w900, color: Color(0xFF102A5C))),
                  const SizedBox(height: 7),
                  const Text('Marketplace modern • Rekber aman', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7A90))),
                  const SizedBox(height: 30),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline), labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)))),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: password,
                    obscureText: hide,
                    autocorrect: false,
                    enableSuggestions: false,
                    onSubmitted: (_) => login(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      labelText: 'Password',
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                      suffixIcon: IconButton(onPressed: () => setState(() => hide = !hide), icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: loading ? null : login,
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF126BFF), minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
                    child: Text(loading ? 'MEMPROSES...' : 'MASUK'),
                  ),
                  const SizedBox(height: 14),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('Belum punya akun? '),
                    TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text('DAFTAR')),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    ]),
  );

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }
}

class _Glow extends StatelessWidget {
  const _Glow();
  @override
  Widget build(BuildContext context) => Container(
    width: 260,
    height: 260,
    decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF78B7FF).withValues(alpha: .28)),
  );
}