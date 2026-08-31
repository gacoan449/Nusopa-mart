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
            if (!profile.hasData) return const _Loading();
            final data = profile.data!.data();
            final role = (data?['role'] ?? 'BUYER').toString().toUpperCase();
            switch (role) {
              case 'ADMIN': return const SuperAdminDashboard();
              case 'SELLER': return const SellerDashboard();
              default: return const HomeScreen();
            }
          },
        );
      },
    );
  }
}
class _Loading extends StatelessWidget {
  const _Loading();
  @override Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
