import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order_model.dart';

class TrackingScreen extends StatelessWidget {
  final OrderModel order;

  const TrackingScreen({super.key, required this.order});

  // Fungsi internal untuk membuka Chrome / Browser eksternal menuju web ekspedisi
  Future<void> _bukaLinkChrome(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka link pelacakan logistik.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Pengiriman', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CARD STATUS PESANAN MEWAH
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping, color: Color(0xFFFF5722), size: 32),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status Pesanan', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(
                        order.status,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFFFF5722)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // INFORMASI LOGISTIK YANG DI-INPUT SELLER
            Text('Informasi Resi & Kurir', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Ekspedisi', order.namaEkspedisi ?? 'Sedang diproses seller'),
                  const Divider(height: 24, color: Color(0xFFF1F3F5)),
                  _buildInfoRow('Nomor Resi', order.nomorResi ?? 'Belum tersedia'),
                  const Divider(height: 24, color: Color(0xFFF1F3F5)),
                  
                  // BUKTI FOTO RESI FISIK (Cadangan pembeli)
                  Text('Foto Resi Fisik:', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  order.fotoResiUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            order.fotoResiUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 150,
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        )
                      : Container(
                          height: 60,
                          width: double.infinity,
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                          child: const Center(child: Text('Foto resi belum diunggah oleh seller', style: TextStyle(color: Colors.grey, fontSize: 12))),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // TOMBOL UTAMA KEREN UNTUK BUKA GOOGLE CHROME (PELACAKAN LUAR)
            if (order.linkCekLogistik != null && order.linkCekLogistik!.isNotEmpty)
              GestureDetector(
                onTap: () => _bukaLinkChrome(context, order.linkCekLogistik!),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF5722), Color(0xFFE64A19)]),
                    borderRadius: BorderRadius.circular(26), // Bentuk kapsul mewah
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFFF5722).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Lacak di Google Chrome',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
      ],
    );
  }
}
