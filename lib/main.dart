import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart'; // Mengimpor halaman login nyata

void main() {
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
        primaryColor: const Color(0xFFFF5722), // Warna dasar Oranye Premium Nusopa
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5722),
          primary: const Color(0xFFFF5722),
        ),
        // Mengubah seluruh font aplikasi menjadi Inter agar elegan, mewah, dan tidak kaku
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Latar belakang abu-abu sangat muda premium
      ),
      // PINTU UTAMA SEKARANG DIALIKKAN KE HALAMAN LOGIN DATA NYATA
      home: const LoginScreen(),
    );
  }
}
