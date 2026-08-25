import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_model.dart';
import '../widgets/custom_button.dart'; 
import 'tracking_screen.dart';
import 'seller_dashboard.dart'; 
import 'admin_core.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Warna Khas Elegan (Navy Blue & Pure White)
  static const Color primaryBlue = Color(0xFF1A237E); // Deep Navy Blue
  static const Color bgCanvas = Color(0xFFF8FAFC);    // Cool Soft White

  // Simulasi state data produk dari database (kosong agar seller yang mengisi)
  List<dynamic> dynamicProducts = []; 
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCanvas, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: bgCanvas,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari koleksi eksklusif...',
              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: primaryBlue, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: primaryBlue),
            onPressed: () {
              // TODO: Navigasi ke Keranjang
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: primaryBlue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatAdminScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _currentIndex == 0 
          ? _buildHomeContent() 
          : _currentIndex == 1 
              ? _buildVideoContent() 
              : TrackingScreen(
                  order: const OrderModel(
                    orderId: "TRX-10029384",
                    buyerId: "USER-99281", 
                    sellerId: "TOKO-11029", 
                    productName: "Premium Elegant Daily Wear",
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
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black12, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: primaryBlue, 
          unselectedItemColor: Colors.grey.shade400,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Discover'),
            BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), activeIcon: Icon(Icons.play_circle), label: 'Live'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_none), activeIcon: Icon(Icons.notifications), label: 'Updates'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      color: primaryBlue,
      backgroundColor: Colors.white,
      onRefresh: () async {
        // TODO: Panggil fungsi API fetch data produk di sini
        await Future.delayed(const Duration(seconds: 1));
      },
      child: CustomScrollView(
        slivers: [
          // Banner Utama Elegan
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryBlue, Color(0xFF283593)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: PageView(
                  children: [
                    _buildBannerPlaceholder('Exclusive Pre-Fall Collection'),
                    _buildBannerPlaceholder('Member Only Privileges'),
                  ],
                ),
              ),
            ),
          ),

          // Menu Kategori Minimalis
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCategoryItem(Icons.diamond_outlined, 'Luxury'),
                  _buildCategoryItem(Icons.checkroom_outlined, 'Boutique'),
                  _buildCategoryItem(Icons.card_membership, 'Rewards'),
                  _buildCategoryItem(Icons.add_business_outlined, 'Become Seller', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SellerDashboard()),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: Divider(color: Colors.black12, thickness: 0.5)),

          // Judul Seksi Produk
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'CURATED FOR YOU',
                style: GoogleFonts.inter(
                  fontSize: 13, 
                  fontWeight: FontWeight.w700, 
                  letterSpacing: 1.2,
                  color: primaryBlue,
                ),
              ),
            ),
          ),

          // Logika Produk Dinamis
          if (dynamicProducts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 20,
                            )
                          ],
                        ),
                        child: Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Koleksi Kosong',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: primaryBlue),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada produk eksklusif yang dirilis oleh mitra.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.70,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // TODO: Ganti dengan mapping dari dynamicProducts[index]
                    return const SizedBox(); 
                  },
                  childCount: dynamicProducts.length, 
                ),
              ),
            ),
            
          const SliverToBoxAdapter(child: SizedBox(height: 40)), // Spacer bawah
        ],
      ),
    );
  }

  Widget _buildBannerPlaceholder(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white, 
            fontWeight: FontWeight.w300, 
            fontSize: 20,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Membuka koleksi $label...'),
            backgroundColor: primaryBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(icon, color: primaryBlue, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black87),
          )
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Text(
          'Live Showcase Eksklusif',
          style: GoogleFonts.inter(color: Colors.white, letterSpacing: 1.0),
        ),
      ),
    );
  }
}
