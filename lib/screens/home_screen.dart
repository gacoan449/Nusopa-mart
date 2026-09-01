import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
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

  static const Color primaryBlue = Color(0xFFFF5722);
  static const Color bgCanvas = Color(0xFFF6F7F9);
  final PageController _bannerController = PageController(viewportFraction: .92);
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int _secondsLeft = 5124;
  Timer? _timer;

  @override
  void initState() { super.initState(); _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted && _secondsLeft > 0) setState(() => _secondsLeft--); }); }
  @override
  void dispose() { _timer?.cancel(); _bannerController.dispose(); _searchController.dispose(); super.dispose(); }

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
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
            decoration: InputDecoration(
              hintText: 'Cari produk, toko, atau kategori...',
              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: primaryBlue, size: 20),
              suffixIcon: _query.isEmpty ? null : IconButton(icon: const Icon(Icons.close), onPressed: () { _searchController.clear(); setState(() => _query = ''); }),
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
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'Jual'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Pesanan'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Saya'),
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
              child: SizedBox(
                height: 170,
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
                  controller: _bannerController,
                  children: [
                    _buildBannerPlaceholder('BELANJA AMAN DENGAN REKBER', subtitle: 'Dana transaksi mengikuti alur aman Nusopa.Mart', icon: Icons.shield_outlined),
                    _buildBannerPlaceholder('PROMO PENGGUNA BARU', subtitle: 'Voucher dan promo dapat diatur manual oleh Admin', icon: Icons.local_offer_outlined),
                    _buildBannerPlaceholder('JUAL BARANGMU', subtitle: 'Kirim sendiri lewat ekspedisi pilihanmu', icon: Icons.storefront_outlined),
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
                  _buildCategoryItem(Icons.shield_outlined, 'Rekber'),
                  _buildCategoryItem(Icons.local_fire_department_outlined, 'Promo'),
                  _buildCategoryItem(Icons.shopping_bag_outlined, 'Pesanan'),
                  _buildCategoryItem(Icons.add_business_outlined, 'Jual', onTap: () {
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
                'REKOMENDASI UNTUK KAMU',
                style: GoogleFonts.inter(
                  fontSize: 13, 
                  fontWeight: FontWeight.w700, 
                  letterSpacing: 1.2,
                  color: primaryBlue,
                ),
              ),
            ),
          ),

          // Produk nyata dari Firestore + Skeleton Loading
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .68, crossAxisSpacing: 12, mainAxisSpacing: 12),
                    delegate: SliverChildBuilderDelegate((_, __) => _buildSkeletonCard(), childCount: 6),
                  ),
                );
              }
              if (snapshot.hasError) return SliverToBoxAdapter(child: _buildEmptyState('Produk belum dapat dimuat', Icons.cloud_off_outlined));
              var docs = snapshot.data?.docs ?? [];
              if (_query.isNotEmpty) docs = docs.where((d) {
                final x = d.data();
                return ('${x['name'] ?? x['productName'] ?? ''} ${x['category'] ?? ''} ${x['storeName'] ?? ''}').toLowerCase().contains(_query);
              }).toList();
              if (docs.isEmpty) return SliverToBoxAdapter(child: _buildEmptyState('Belum ada produk', Icons.inventory_2_outlined));
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .60, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  delegate: SliverChildBuilderDelegate((context, index) => _buildProductCard(docs[index].data()), childCount: docs.length),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)), // Spacer bawah
        ],
      ),
    );
  }

  Widget _buildBannerPlaceholder(String text, {String? subtitle, IconData icon = Icons.campaign_outlined}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(children: [Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(text, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)), const SizedBox(height: 8), Text(subtitle ?? '', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)), const SizedBox(height: 12), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(20)), child: Text('LIHAT SEKARANG', style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))) ])), Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withOpacity(.15), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 38))]),
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


  Widget _buildSkeletonCard() => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.all(10), child: Column(children:[Expanded(child: Container(color: Colors.grey.shade200)), const SizedBox(height: 10), Container(height: 10, color: Colors.grey.shade200), const SizedBox(height: 7), Container(height: 10, width: 80, color: Colors.grey.shade200)]));
  Widget _buildEmptyState(String message, IconData icon) => Padding(padding: const EdgeInsets.all(32), child: Column(children:[Icon(icon,size:44,color:Colors.grey.shade400),const SizedBox(height:10),Text(message,style:GoogleFonts.inter(fontWeight:FontWeight.w700)),const SizedBox(height:5),Text('Produk seller akan muncul otomatis di sini.',style:GoogleFonts.inter(fontSize:11,color:Colors.grey))]));
  Widget _buildProductCard(Map<String,dynamic> x) { final name=(x['name']??x['productName']??'Produk Nusopa').toString(); final price=x['price']??x['productPrice']??0; final image=(x['imageUrl']??x['image']??'').toString(); final sold=x['sold']??0; final rating=x['rating']??5.0; return Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),boxShadow:[BoxShadow(color:Colors.black.withOpacity(.035),blurRadius:12)]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:ClipRRect(borderRadius:const BorderRadius.vertical(top:Radius.circular(16)),child:image.isEmpty?Container(color:Colors.grey.shade100,child:const Center(child:Icon(Icons.image_outlined,color:Colors.grey,size:40))):Image.network(image,width:double.infinity,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Container(color:Colors.grey.shade100,child:const Icon(Icons.broken_image_outlined))))),Padding(padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,maxLines:2,overflow:TextOverflow.ellipsis,style:GoogleFonts.inter(fontSize:12,fontWeight:FontWeight.w600)),const SizedBox(height:6),Text('Rp$price',style:GoogleFonts.inter(fontSize:14,fontWeight:FontWeight.w800,color:primaryBlue)),const SizedBox(height:5),Text('⭐ $rating  |  Terjual $sold',style:GoogleFonts.inter(fontSize:9,color:Colors.grey)),const SizedBox(height:7),Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:4),decoration:BoxDecoration(color:const Color(0xFFEAF7EF),borderRadius:BorderRadius.circular(7)),child:Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.shield_outlined,size:11,color:Color(0xFF16803A)),const SizedBox(width:3),Text('Rekber Aman',style:GoogleFonts.inter(fontSize:9,fontWeight:FontWeight.w700,color:const Color(0xFF16803A)))]) )]))])); }

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
