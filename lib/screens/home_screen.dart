import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_model.dart';

class TrackingScreen extends StatelessWidget {
  final OrderModel order;

  const TrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan background abu-abu khas e-commerce untuk kontras kartu putih
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: Text(
          'Detail Pengiriman',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. BLOK STATUS PESANAN (Khas Shopee dengan latar oranye/merah tipis)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping, color: Colors.white, size: 28),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.status,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pesanan Anda sedang dalam perjalanan oleh kurir.',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. KARTU INFORMASI RESI & KURIR
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFFF5722), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Informasi Resi & Kurir',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                  ),
                  
                  // Detail Ekspedisi
                  _buildDetailRow('Ekspedisi', order.namaEkspedisi, isBold: true),
                  const SizedBox(height: 12),
                  
                  // Detail Nomor Resi + Tombol Salin
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nomor Resi',
                            style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.nomorResi,
                            style: GoogleFonts.inter(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: order.nomorResi));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nomor resi berhasil disalin!')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFF5722)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'SALIN',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFF5722),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. KARTU BUKTI FOTO RESI FISIK
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Foto Resi Fisik:',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black77,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Menangani jika foto kosong / default placeholder
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 40),
                          SizedBox(height: 8),
                          Text('Belum ada foto resi fisik', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. TOMBOL LACAK UTAMA DI BAWAH KARTU
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    // Logika membuka linkCekLogistik lewat url_launcher
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Lacak di Google Chrome',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
