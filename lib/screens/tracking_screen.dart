import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order_model.dart';

class TrackingScreen extends StatelessWidget {
  final OrderModel order;

  const TrackingScreen({super.key, required this.order});

  // Konstanta Warna Tema Mewah (Navy & Putih)
  static const Color primaryBlue = Color(0xFF1A237E); // Deep Navy Blue
  static const Color secondaryBlue = Color(0xFF283593); // Gradasi Navy
  static const Color textDark = Color(0xFF1E293B); // Dark Slate untuk teks
  static const Color bgCanvas = Color(0xFFF8FAFC); // Background Putih Bersih

  // Fungsi internal membuka Browser eksternal (Chrome/Safari)
  Future<void> _bukaLinkWeb(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Browser tidak merespon.';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka web pelacakan. Pastikan link valid.', style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
          backgroundColor: Colors.red.shade800,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Fungsi menyalin nomor resi ke Clipboard HP pengguna
  void _salinResi(BuildContext context, String resi) {
    Clipboard.setData(ClipboardData(text: resi));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nomor resi JNE berhasil disalin!', style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCanvas,
      appBar: AppBar(
        title: Text('Lacak Pengiriman', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: primaryBlue)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        iconTheme: const IconThemeData(color: primaryBlue),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KARTU STATUS PESANAN (PREMIUM GRADIENT)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, secondaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status Saat Ini', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          order.status,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // INFORMASI RESI & KURIR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text('Detail Logistik', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fallback string langsung diarahkan ke JNE
                  _buildInfoRow('Mitra Ekspedisi', order.namaEkspedisi ?? 'JNE (Manual Flat Rate)'),
                  const Divider(height: 32, color: Color(0xFFF1F3F5)),
                  
                  // Baris Nomor Resi dengan Tombol Salin
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _buildInfoRow('Nomor Resi', order.nomorResi ?? 'Belum diterbitkan penjual'),
                      ),
                      if (order.nomorResi != null && order.nomorResi!.isNotEmpty)
                        GestureDetector(
                          onTap: () => _salinResi(context, order.nomorResi!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: primaryBlue.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.copy, size: 14, color: primaryBlue),
                                const SizedBox(width: 6),
                                Text('Salin', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: primaryBlue)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 32, color: Color(0xFFF1F3F5)),
                  
                  // BUKTI FOTO RESI FISIK
                  Text('Bukti Foto Resi Fisik:', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  order.fotoResiUrl != null && order.fotoResiUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            order.fotoResiUrl!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder('Gagal memuat gambar resi'),
                          ),
                        )
                      : _buildImagePlaceholder('Penjual belum mengunggah resi fisik'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // TOMBOL UTAMA CEK RESI EKSTERNAL (PREMIUM GRADIENT)
            if (order.linkCekLogistik != null && order.linkCekLogistik!.isNotEmpty)
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
                    BoxShadow(color: primaryBlue.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6)),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Beri notifikasi salin resi otomatis sebelum buka browser
                    if (order.nomorResi != null) {
                      Clipboard.setData(ClipboardData(text: order.nomorResi!));
                    }
                    _bukaLinkWeb(context, order.linkCekLogistik!);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.travel_explore, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Lacak di Web JNE',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Widget Pembantu: Info Baris Teks
  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: textDark)),
      ],
    );
  }

  // Widget Pembantu: Placeholder Gambar Resi
  Widget _buildImagePlaceholder(String message) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgCanvas, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, color: Colors.grey.shade400, size: 36),
            const SizedBox(height: 12),
            Text(message, style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
