import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Diaktifkan saat integrasi backend

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  // --- STATE SIMULASI BACKEND (Ganti dengan Stream/Future Firestore nantinya) ---
  int _sisaTiket = -2; // Contoh kondisi kredit darurat
  int _pesananBaru = 5;
  int _siapDikirim = 3;
  double _saldoCair = 1450000;
  bool _isLoading = false;

  // Konstanta Warna Tema Profesional
  static const Color primaryColor = Color(0xFFFF5722);
  static const Color batikDark = Color(0xFF2C1B18);
  static const Color batikGold = Color(0xFFD4AF37);
  static const Color bgCanvas = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    // Logika Pemblokiran Toko Otomatis
    bool isTokoDibekukan = _sisaTiket <= -5;

    return Scaffold(
      backgroundColor: bgCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          "Pusat Penjual",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: batikDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: batikDark),
            tooltip: 'Pengaturan Toko',
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : CustomScrollView(
              slivers: [
                // BANNER PERINGATAN TIKET (Muncul jika tiket <= 0)
                if (_sisaTiket <= 0)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: isTokoDibekukan ? Colors.red.shade900 : Colors.orange.shade100,
                      child: Row(
                        children: [
                          Icon(
                            isTokoDibekukan ? Icons.block : Icons.warning_amber_rounded,
                            color: isTokoDibekukan ? Colors.white : Colors.orange.shade900,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isTokoDibekukan
                                  ? "TOKO DIBEKUKAN! Saldo tiket Anda $_sisaTiket. Harap Top-Up ke Admin untuk menerima pesanan kembali."
                                  : "PERHATIAN: Saldo tiket Anda $_sisaTiket (Kredit Darurat). Batas maksimal adalah -5. Segera Top-Up!",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isTokoDibekukan ? Colors.white : Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // HEADER PROFIL TOKO
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey.shade200,
                          child: const Icon(Icons.store, size: 30, color: primaryColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Toko Nusantara Sejahtera",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: batikDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isTokoDibekukan ? Colors.red.shade50 : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isTokoDibekukan ? "Toko Tutup (Limit Tiket)" : "Toko Aktif",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isTokoDibekukan ? Colors.red : Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: const BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text("Lihat Toko", style: GoogleFonts.inter(fontSize: 12)),
                        )
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // METRIK UTAMA (Pesanan & Saldo)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildListDelegate([
                      _buildMetricCard(
                        title: "Pesanan Baru",
                        value: _pesananBaru.toString(),
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                        onTap: () {}, // Navigasi ke List Pesanan
                      ),
                      _buildMetricCard(
                        title: "Siap Dikirim",
                        value: _siapDikirim.toString(),
                        icon: Icons.local_shipping_outlined,
                        color: Colors.orange,
                        onTap: () {}, // Navigasi ke Form Input Resi
                      ),
                      _buildMetricCard(
                        title: "Saldo Berhasil",
                        value: "Rp 1.45M", // Format uang disederhanakan untuk UI
                        icon: Icons.account_balance_wallet_outlined,
                        color: Colors.green,
                        onTap: () {}, // Navigasi ke Penarikan Dana
                      ),
                      _buildMetricCard(
                        title: "Sisa Tiket",
                        value: _sisaTiket.toString(),
                        icon: Icons.confirmation_number_outlined,
                        color: _sisaTiket < 0 ? Colors.red : batikDark,
                        onTap: () {}, // Navigasi ke Top Up Tiket
                      ),
                    ]),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // MENU MANAJEMEN SELLER
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "Manajemen Toko",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: batikDark,
                            ),
                          ),
                        ),
                        _buildMenuItem(Icons.inventory_2_outlined, "Produk Saya", "Atur stok & harga"),
                        _buildMenuItem(Icons.add_box_outlined, "Tambah Produk Baru", "Upload foto & deskripsi"),
                        _buildMenuItem(Icons.account_balance_outlined, "Penarikan Dana", "Tarik saldo ke rekening"),
                        _buildMenuItem(Icons.add_shopping_cart, "Beli Tiket (Top-Up)", "Konfirmasi manual ke Admin"),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // MENU PUSAT KOMUNIKASI (Chat Pembeli & Admin)
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "Pusat Komunikasi",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: batikDark,
                            ),
                          ),
                        ),
                        _buildMenuItem(Icons.forum_outlined, "Chat Pembeli", "Balas pesan pelanggan"),
                        _buildMenuItem(Icons.support_agent, "Pusat Bantuan Admin", "Kendala transaksi & resi", isPrimary: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Widget Pembantu untuk Metrik Kotak
  Widget _buildMetricCard({required String title, required String value, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Pembantu untuk List Menu
  Widget _buildMenuItem(IconData icon, String title, String subtitle, {bool isPrimary = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isPrimary ? primaryColor.withOpacity(0.1) : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isPrimary ? primaryColor : batikDark, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: batikDark),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {}, // Tambahkan logika navigasi halaman
    );
  }
}
