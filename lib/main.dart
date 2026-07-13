import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart'; 

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
        primaryColor: const Color(0xFFFF5722),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5722),
        ),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      // Kata const di depan HomeScreen sudah dihapus agar tidak error saat build rilis
      home: HomeScreen(), 
    );
  }
}
