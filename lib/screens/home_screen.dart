import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_model.dart';
import '../widgets/custom_button.dart'; 
import 'tracking_screen.dart';
import 'seller_dashboard.dart'; 
import 'chat_admin_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Konstanta Warna Tema Batik Modern (Deep Indigo & Heritage Gold/Amber & Shopee Orange)
  static const Color primaryColor = Color(0xFFFF5722); // Orange Utama
  static const Color batikDark = Color(0xFF2C1B18);    // Cokelat Batik Tua
  static const Color batikGold = Color(0xFFD4AF37);    // Emas Heritage
  static const Color bgCanvas = Color(0xFFF8F9FA);     // Background General

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCanvas, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(12), 
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari produk, merek, atau toko...',
              hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: primaryColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront, color: primaryColor),
            tooltip: 'Kemitraan Seller',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SellerDashboard()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: batikDark),
            tooltip: 'Layanan Pengguna & Konfirmasi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatAdminScreen()),
              );
            },
          )
        ],
      ),
      body: _currentIndex == 0 
          ? _buildHomeContent() 
          : _currentIndex == 1 
              ? _buildVideoContent() 
              : TrackingScreen(
                  order: OrderModel(
                    orderId: "TRX-10029384",
                    productName: "Premium Elegant Daily Wear Edition XL",
                    productImage: "",
                    price: 185000,
                    status: "DALAM PENGIRIMAN",
                    namaEkspedisi: "J&T Express",
                    nomorResi: "JT9920118273",
                    fotoResiUrl: "https://images.unsplash.com", 
                    linkCekLogistik: "https://jet.co.id", 
                  ),
                ),
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
          selectedItemColor: primaryColor, 
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Rekomendasi'),
            BottomNavigationBarItem(icon: Icon(Icons.slideshow_outlined), activeIcon: Icon(Icons.slideshow), label: 'Review Live'),
            BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), activeIcon: Icon(Icons.local_shipping), label: 'Transaksi'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return CustomScrollView(
      slivers: [
        // PROMOTIONAL BANNER DENGAN AKSEN MOTIF BATIK MODERN
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [batikDark, Color(0xFF4A312C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: NetworkImage('https://www.transparenttextures.com/patterns/batik-fabric.png'), // Aksen tekstur batik transparan bawaan web
                  repeat: ImageRepeat.repeat,
                  opacity: 0.15,
                ),
                boxShadow: [
                  BoxShadow(
                    color: batikDark.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: batikGold,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PROMO KEBANGGAAN',
                        style: GoogleFonts.inter(color: batikDark, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kurasi Produk Terbaik\nUntuk Kenyamanan Anda',
                      style: GoogleFonts.inter(
                        color: Colors.white, 
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // SEKSI MENU KATEGORI POPULER (Gaya Grid Shopee Menu)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCategoryItem(Icons.style, 'Fashion'),
                _buildCategoryItem(Icons.devices, 'Elektronik'),
                Icons.health_and_safety.hashCode != 0 ? _buildCategoryItem(Icons.health_and_safety, 'Kecantikan') : _buildCategoryItem(Icons.face, 'Kecantikan'),
                _buildCategoryItem(Icons.home_max, 'Peralatan'),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // SUB-TITLE
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                Text(
                  'Koleksi Flash Sale Manual',
                  style: GoogleFonts.inter(
                    fontSize: 15, 
                    fontWeight: FontWeight.bold, 
                    color: batikDark,
                  ),
                ),
                Text(
                  'Lihat Semua',
                  style: GoogleFonts.inter(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600),
                )
              ],
            ),
          ),
        ),

        // GRID PRODUK PROFESIONAL
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // List Mock Data Profesional tanpa Dummy Desa
                List<String> titles = [
                  'Smartwatch Series X Waterproof',
                  'Casual Sneakers Breathable Solid',
                  'Premium Cotton T-Shirt Oversized',
                  'Ergonomic Wireless Mouse Silent'
                ];
                List<String> prices = ['Rp 249.000', 'Rp 389.000', 'Rp 125.000', 'Rp 89.000'];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          child: const Center(
                            child: Icon(Icons.image, size: 40, color: Colors.grey),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titles[index % 4], 
                              maxLines: 2, 
                              overflow: TextOverflow.ellipsis, 
                              style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13, color: batikDark),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              prices[index % 4], 
                              style: GoogleFonts.inter(
                                color: primaryColor, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: batikGold, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  '4.8 | Terjual Manual',
                                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                                )
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
              childCount: 4, 
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildCategoryItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.orange.shade100, width: 1),
          ),
          child: Icon(icon, color: batikDark, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: batikDark),
        )
      ],
    );
  }

  Widget _buildVideoContent() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_outline, size: 80, color: Colors.white54),
                const SizedBox(height: 16),
                Text(
                  'Review Produk Interaktif & Live Promosi',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: CustomButton(
              text: 'Hubungi Merchant Untuk Produk Ini',
              icon: Icons.shopping_bag_outlined,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Membuka Chat Form Pemesanan Manual...')),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
