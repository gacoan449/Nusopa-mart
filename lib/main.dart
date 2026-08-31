import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NusopaMartApp());
}

class NusopaMartApp extends StatelessWidget {
  const NusopaMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF5722);
    return MaterialApp(
      title: 'Nusopa.Mart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: orange),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const LoginScreen(),
    );
  }
}
