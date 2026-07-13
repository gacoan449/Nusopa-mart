import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart'; // <-- 1. Wajib impor ini
import 'firebase_options.dart'; // <-- 2. Otomatis ada setelah menjalankan 'flutterfire configure'
import 'screens/login_screen.dart';

void main() async {
  // <-- 3. Ubah jadi async
  WidgetsFlutterBinding.ensureInitialized(); // <-- 4. Wajib untuk inisialisasi native plugin
  
  // 5. Inisialisasi Firebase sebelum runApp berjalan
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const NusopaMartApp());
}

class NusopaMartApp extends StatelessWidget {
  const NusopaMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nusopa.Mart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFFFF5722),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5722),
          primary: const Color(0xFFFF5722), // Mengunci warna utama agar konsisten
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme, // Penerapan font global yang lebih aman
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
