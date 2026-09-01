import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_core.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'seller_dashboard.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, auth) {
        if (auth.connectionState == ConnectionState.waiting) return const _Loading();
        final user = auth.data;
        if (user == null) return const LoginScreen();

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, profile) {
            if (profile.connectionState == ConnectionState.waiting) return const _Loading();
            if (profile.hasError) {
              return _ProfileProblem(
                title: 'Profil tidak dapat dibaca',
                message: 'Firebase Authentication berhasil, tetapi profil users/' + user.uid + ' tidak dapat dibaca. Periksa Firestore Rules dan pastikan dokumen profil menggunakan UID Firebase Authentication.',
              );
            }
            final doc = profile.data;
            if (doc == null || !doc.exists) {
              return _ProfileProblem(
                title: 'Profil akun belum ditemukan',
                message: 'Akun ' + (user.email ?? '') + ' sudah masuk, tetapi dokumen users/' + user.uid + ' belum ada. Role ADMIN/SELLER harus disimpan pada dokumen dengan ID UID Firebase Authentication, bukan ID email atau ID acak.',
              );
            }

            final data = doc.data() ?? <String, dynamic>{};
            final role = (data['role'] ?? 'BUYER').toString().trim().toUpperCase();
            switch (role) {
              case 'ADMIN':
              case 'SUPER_ADMIN':
                return const SuperAdminDashboard();
              case 'SELLER':
                return const SellerDashboard();
              default:
                return const HomeScreen();
            }
          },
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _ProfileProblem extends StatelessWidget {
  final String title;
  final String message;
  const _ProfileProblem({required this.title, required this.message});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F8FF),
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.admin_panel_settings_outlined, size: 52, color: Color(0xFF126BFF)),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF607089), height: 1.4)),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('KELUAR'),
              ),
            ]),
          ),
        ),
      ),
    ),
  );
}