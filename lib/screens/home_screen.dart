import 'package:flutter/material:';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Latar belakang abu-abu super muda premium
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(12), // Melengkung mewah, tidak kaku
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari produk di Nusopa.Mart...',
              hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.orange),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.black87),
            onPressed: () {
              // Jalur ke fitur chat admin/seller
            },
          )
        ],
      ),
      body: _currentIndex == 0 ? _buildHomeContent() : _buildVideoContent(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color(0xFFFF5722), // Oranye khas Shopee premium
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.slideshow_outlined), activeIcon: Icon(Icons.slideshow), label: 'Video'),
            BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), label: 'Pesanan'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Promo Melengkung
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'Nusopa.Mart\nSederhana tapi Mewah',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          
          // Judul Kategori
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Rekomendasi Produk',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          
          // Grid Produk Contoh
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: const Center(
                          child: Icon(Icons.fastfood, size: 50, color: Color(0xFFFF5722)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Produk Sembako $index', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Rp 15.000', style: GoogleFonts.inter(color: const Color(0xFFFF5722), fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Text(
          'Halaman Short Video Berputar Fullscreen\n(Sederhana Mirip TikTok / Shopee Video)',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
    );
  }
}
