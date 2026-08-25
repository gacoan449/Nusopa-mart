import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Wajib diaktifkan untuk keamanan produksi
// import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'home_screen.dart';
// import 'register_screen.dart'; // File pendaftaran (dibuat nanti)

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailPhoneController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Konstanta Warna Tema Mewah (Navy Blue & Cool White)
  static const Color primaryBlue = Color(0xFF1A237E); // Deep Navy Blue
  static const Color secondaryBlue = Color(0xFF283593); // Gradasi Navy
  static const Color textDark = Color(0xFF1E293B); // Dark Slate untuk teks
  static const Color bgCanvas = Color(0xFFF8FAFC); // Background Putih Bersih

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _prosesLoginProfesional() async {
    if (_emailPhoneController.text.isEmpty || _passController.text.isEmpty) {
      _notif("Mohon lengkapi email/nomor HP dan password Anda.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      /* 
      // LOGIKA FIREBASE AUTHENTICATION (Standar Industri)
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailPhoneController.text.trim(),
        password: _passController.text,
      );
      
      // Ambil role user dari Firestore setelah Auth berhasil
      // DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      */

      // Simulasi delay jaringan
      await Future.delayed(const Duration(seconds: 2));

      _notif("Autentikasi Berhasil. Selamat Datang!");
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      _notif("Kredensial tidak valid atau akun tidak ditemukan.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _notif(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCanvas, // Menggunakan background soft white
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER LOGO & BRANDING (Mewah dengan Gradasi)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryBlue, secondaryBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, size: 56, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Nusopa.Mart',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 28, 
                    fontWeight: FontWeight.w800, 
                    color: primaryBlue,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kurasi Kualitas, Kenyamanan Berbelanja',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13, letterSpacing: 0.5),
                ),
                const SizedBox(height: 48),

                // FORM INPUT KREDENSIAL
                Text(
                  'Masuk ke Akun Anda',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: textDark),
                ),
                const SizedBox(height: 16),
                
                // Form Email/HP
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: TextField(
                    controller: _emailPhoneController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(fontSize: 14, color: textDark),
                    decoration: InputDecoration(
                      labelText: 'Email atau Nomor Handphone',
                      labelStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: const Icon(Icons.person_outline, color: primaryBlue, size: 22),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Form Password
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: TextField(
                    controller: _passController,
                    obscureText: !_isPasswordVisible,
                    style: GoogleFonts.inter(fontSize: 14, color: textDark),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_outline, color: primaryBlue, size: 22),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                      ),
                    ),
                  ),
                ),
                
                // LUPA PASSWORD ALIGN RIGHT
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      _notif("Membuka halaman pemulihan sandi...");
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Lupa Password?',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // TOMBOL LOGIN UTAMA (Dengan Gradasi)
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [primaryBlue, secondaryBlue],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _prosesLoginProfesional,
                    child: _isLoading 
                        ? const SizedBox(
                            height: 24, 
                            width: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                          )
                        : Text(
                            'Masuk Aplikasi', 
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white, letterSpacing: 0.5)
                          ),
                  ),
                ),
                const SizedBox(height: 32),

                // DIVIDER DAFTAR
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "Atau",
                        style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 20),

                // TOMBOL DAFTAR / MULAI JUAL (Minimalis Outline)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                    side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    _notif("Navigasi ke Halaman Registrasi Pembeli/Penjual");
                  },
                  child: Text(
                    'Daftar Akun Nusopa.Mart',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
