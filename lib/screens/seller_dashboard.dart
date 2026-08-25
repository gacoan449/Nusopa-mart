import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Tambahkan package intl di pubspec.yaml untuk format Rupiah
// import 'package:cloud_firestore/cloud_firestore.dart'; // Diaktifkan saat integrasi backend/JSON DB

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  // --- STATE REAL (Kosong/Default, siap diisi dari JSON Database) ---
  int _sisaTiket = 0; 
  int _pesananBaru = 0;
  int _siapDikirim = 0;
  double _saldoCair = 0.0;
  String _namaToko = "Memuat Toko...";
  String _nomorHpToko = ""; // Untuk validasi sinkronisasi ke PPOB
  bool _isLoading = true;

  // Konstanta Warna Tema Mewah (Navy & Putih)
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color secondaryBlue = Color(0xFF283593);
  static const Color textDark = Color(0xFF1E293B);
  static const Color bgCanvas = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _fetchDataTokoReal();
  }

  // Simulasi fetch data dari JSON / Database backend
  Future<void> _fetchDataTokoReal() async {
    // TODO: Ganti dengan logika get data JSON sesuai ID Seller
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      setState(() {
        _namaToko = "Toko Official Anda"; // Hasil fetch DB
        _nomorHpToko = "081234567890"; // Hasil fetch DB
        _sisaTiket = 10; // Hasil fetch DB
        _pesananBaru = 0; // Hasil fetch DB
        _siapDikirim = 0; // Hasil fetch DB
        _saldoCair = 0.0; // Hasil fetch DB
        _isLoading = false;
      });
    }
  }

  void _notif(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatRupiah(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Logika Pemblokiran Toko Otomatis
    bool isTokoDibekukan = _sisaTiket <= -5;
    bool isPeringatanTiket = _sisaTiket <= 0 && !isTokoDibekukan;

    return Scaffold(
      backgroundColor: bgCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        iconTheme: const IconThemeData(color: primaryBlue),
        title: Text(
          "Pusat Penjual",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: primaryBlue,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: primaryBlue),
            tooltip: 'Pengaturan Toko',
            onPressed: () {
              _notif("Membuka pengaturan toko...");
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
              color: primaryBlue,
              onRefresh: _fetchDataTokoReal,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // BANNER PERINGATAN TIKET (Muncul jika tiket <= 0)
                  if (isPeringatanTiket || isTokoDibekukan)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: isTokoDibekukan ? const Color(0xFFB91C1C) : const Color(0xFFFEF08A),
                        child: Row(
                          children: [
                            Icon(
                              isTokoDibekukan ? Icons.block : Icons.warning_amber_rounded,
                              color: isTokoDibekukan ? Colors.white : const Color(0xFF854D0E),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isTokoDibekukan
                                    ? "TOKO DIBEKUKAN! Saldo tiket Anda $_sisaTiket. Harap Top-Up untuk buka toko kembali."
                                    : "PERHATIAN: Saldo tiket $_sisaTiket (Kredit Darurat). Batas maksimal -5. Segera Top-Up!",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isTokoDibekukan ? Colors.white : const Color(0xFF854D0E),
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
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bgCanvas,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: const Icon(Icons.storefront, size: 28, color: primaryBlue),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _namaToko,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isTokoDibekukan ? Colors.red.shade50 : primaryBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isTokoDibekukan ? "Toko Tutup (Limit Tiket)" : "Toko Aktif",
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isTokoDibekukan ? Colors.red : primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              _notif("Membuka tampilan toko dari sisi pembeli...");
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryBlue,
                              side: const BorderSide(color: primaryBlue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text("Lihat Toko", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // METRIK UTAMA (Pesanan & Saldo Dinamis)
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
                          color: Colors.blue.shade700,
                          onTap: () => _notif("Membuka daftar pesanan masuk..."),
                        ),
                        _buildMetricCard(
                          title: "Siap Dikirim",
                          value: _siapDikirim.toString(),
                          icon: Icons.local_shipping_outlined,
                          color: Colors.orange.shade700,
                          onTap: () => _notif("Membuka pesanan untuk input resi manual JNE..."),
                        ),
                        _buildMetricCard(
                          title: "Saldo Tersedia",
                          value: _formatRupiah(_saldoCair),
                          icon: Icons.account_balance_wallet_outlined,
                          color: Colors.teal.shade700,
                          onTap: () => _notif("Membuka histori saldo Tripay..."),
                        ),
                        _buildMetricCard(
                          title: "Sisa Tiket",
                          value: _sisaTiket.toString(),
                          icon: Icons.confirmation_number_outlined,
                          color: _sisaTiket < 0 ? Colors.red.shade700 : primaryBlue,
                          onTap: () => _notif("Membuka menu Top Up Tiket..."),
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
                                color: textDark,
                              ),
                            ),
                          ),
                          _buildMenuItem(
                            icon: Icons.inventory_2_outlined,
                            title: "Produk Saya",
                            subtitle: "Atur stok & harga",
                            onTap: () => _notif("Membuka daftar produk dari JSON DB..."),
                          ),
                          _buildMenuItem(
                            icon: Icons.add_box_outlined,
                            title: "Tambah Produk Baru",
                            subtitle: "Upload foto & deskripsi",
                            onTap: () => _notif("Membuka form upload produk..."),
                          ),
                          _buildMenuItem(
                            icon: Icons.sync_alt,
                            title: "Sinkronisasi Saldo PPOB",
                            subtitle: "Pindahkan saldo ke aplikasi PPOB (No HP: $_nomorHpToko)",
                            isHighlight: true,
                            onTap: () => _notif("Proses API ke PPOB untuk transfer saldo $_saldoCair..."),
                          ),
                          _buildMenuItem(
                            icon: Icons.local_shipping_outlined,
                            title: "Pengaturan JNE Manual",
                            subtitle: "Input tarif ongkir flat & info resi",
                            onTap: () => _notif("Membuka form setup Ongkir Manual..."),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // MENU PUSAT KOMUNIKASI
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
                              "Bantuan & Komunikasi",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ),
                          _buildMenuItem(
                            icon: Icons.forum_outlined,
                            title: "Chat Pembeli",
                            subtitle: "Balas pesan pelanggan",
                            onTap: () => _notif("Membuka ruang chat pembeli..."),
                          ),
                          _buildMenuItem(
                            icon: Icons.headset_mic_outlined,
                            title: "Hubungi Admin Pusat",
                            subtitle: "Konfirmasi tiket & kendala",
                            onTap: () => _notif("Menghubungkan ke Chat Admin..."),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Widget Pembantu untuk Metrik Kotak (Dibuat lebih elegan & interaktif)
  Widget _buildMetricCard({required String title, required String value, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: value.startsWith('Rp') ? 14 : 20, // Otomatis ngecilin font kalau panjang (Rupiah)
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Pembantu untuk List Menu (Interaktif)
  Widget _buildMenuItem({required IconData icon, required String title, required String subtitle, bool isHighlight = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isHighlight ? primaryBlue.withOpacity(0.1) : bgCanvas,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isHighlight ? primaryBlue : textDark, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600, 
                      fontSize: 14, 
                      color: isHighlight ? primaryBlue : textDark
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
