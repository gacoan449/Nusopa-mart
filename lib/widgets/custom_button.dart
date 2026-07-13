import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final List<Color>? gradientColors;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          // Membuat efek gradasi mewah oranye khas Nusopa.Mart jika warna tidak kustom
          gradient: LinearGradient(
            colors: gradientColors ?? [const Color(0xFFFF5722), const Color(0xFFE64A19)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(26), // Sudut kapsul rounded premium
          boxShadow: [
            BoxShadow(
              color: (gradientColors?.first ?? const Color(0xFFFF5722)).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6), // Efek bayangan halus mengambang
            ),
          ],
        ),
        child: Row(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
