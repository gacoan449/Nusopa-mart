import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final List<Color>? gradientColors;
  final bool isLoading; // Mencegah user klik berkali-kali saat loading database

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.gradientColors,
    this.isLoading = false, // Default false
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed, // Nonaktifkan klik saat loading
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          // Gradasi default menggunakan warna tema Nusopa.Mart
          gradient: LinearGradient(
            colors: isLoading 
                ? [Colors.grey.shade400, Colors.grey.shade500] 
                : gradientColors ?? const [Color(0xFFFF5722), Color(0xFFE64A19)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(26), // Sudut kapsul rounded premium
          boxShadow: [
            if (!isLoading)
              BoxShadow(
                color: (gradientColors?.first ?? const Color(0xFFFF5722)).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6), 
              ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
