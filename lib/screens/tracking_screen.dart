import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Ditambahkan untuk fitur Salin/Copy
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order_model.dart';

class TrackingScreen extends StatelessWidget {
  final OrderModel order;

  const TrackingScreen({super.key, required this.order});

  // Konstanta Warna Tema Profesional
  static const Color primaryColor = Color(0xFFFF5722);
  static const Color batikDark = Color(0xFF2C1B18);
  static const Color bgCanvas = Color(0xFFF8F9FA);

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
          content: Text('Gagal membuka web pelacakan. Pastikan link valid.', style: GoogleFonts.inter(fontSize: 13)),
          backgroundColor: batikDark,
        ),
      );
    }
  }

  // Fungsi menyalin nomor resi ke Clipboard HP pengguna
  void _salinResi(BuildContext context, String resi) {
    Clipboard.setData(ClipboardData(text: resi));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nomor resi berhasil disalin!', style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCanvas,
      appBar: AppBar(
        title: Text('Detail Pengiriman', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: batikDark)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: batikDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KARTU STATUS PESANAN (PREMIUM)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_shipping_outlined, color: primaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status Saat Ini', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          order.status,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: batikDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // INFORMASI RESI & KURIR (DENGAN FITUR COPY)
            Text('Informasi Kurir & Resi', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: batikDark)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Mitra Ekspedisi', order.namaEkspedisi ?? 'Menunggu konfirmasi penjual'),
                  const Divider(height: 32, color: Color(0xFFF1F3F5)),
                  
                  // Baris Nomor Resi dengan Tombol Salin
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _buildInfoRow('Nomor Resi', order.nomorResi ?? 'Belum diterbitkan'),
                      ),
                      if (order.nomorResi != null && order.nomorResi!.isNotEmpty)
                        GestureDetector(
                          onTap: () => _salinResi(context, order.nomorResi!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.copy, size: 14, color: batikDark),
                                const SizedBox(width: 4),
                                Text('Salin', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: batikDark)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 32, color: Color(0xFFF1F3F5)),
                  
                  // BUKTI FOTO RESI FISIK
                  Text('Bukti Foto Resi:', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 12),
                  order.fotoResiUrl != null && order.fotoResiUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            order.fotoResiUrl!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder('Gambar resi gagal dimuat'),
                          ),
                        )
                      : _buildImagePlaceholder('Penjual belum mengunggah foto resi'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // TOMBOL UTAMA CEK RESI EKSTERNAL
            if (order.linkCekLogistik != null && order.linkCekLogistik!.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  // Beri notifikasi salin resi otomatis sebelum buka browser
                  if (order.nomorResi != null) {
                    Clipboard.setData(ClipboardData(text: order.nomorResi!));
                  }
                  _bukaLinkWeb(context, order.linkCekLogistik!);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.travel_explore, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Lacak di Web Ekspedisi',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),
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
        Text(label, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: batikDark)),
      ],
    );
  }

  // Widget Pembantu: Placeholder Gambar Resi
  Widget _buildImagePlaceholder(String message) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, color: Colors.grey.shade400, size: 32),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
