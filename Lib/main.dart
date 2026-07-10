import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import 'main_navigation.dart'; // Nanti kita buat file navigasi ini setelah ini

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Menghubungkan Flutter ke Firebase Anda
  runApp(const NusopaMartApp());
}

class NusopaMartApp extends StatelessWidget {
  const NusopaMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nusopa Mart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue.shade700,
      ),
      // StreamBuilder ini otomatis memantau status login pengguna
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          // Jika user sudah login, langsung lolos masuk ke Menu Utama Aplikasi
          if (snapshot.hasData) {
            return const MainNavigation();
          }
          // Jika belum login / pengguna baru, wajib lewat Halaman Login dulu
          return const AuthScreen();
        },
      ),
    );
  }
}
