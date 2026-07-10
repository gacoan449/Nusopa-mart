import 'package:flutter/material.dart';
import 'package:carousel_slider_plus/carousel_slider_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Simulasi Gambar Spanduk Promo dari Admin
  final List<String> imgBannerList = [
    'https://unsplash.com', // Contoh sepatu
    'https://unsplash.com', // Contoh headphone
  ];

  // Simulasi Daftar Kategori Shopee Style
  final List<Map<String, dynamic>> categories = [
    {"icon": Icons.live_tv, "label": "Shopee Live", "color": Colors.red},
    {"icon": Icons.local_shipping, "label": "Bisa COD", "color": Colors.green},
    {"icon": Icons.flash_on, "label": "Flash Sale", "color": Colors.orange},
    {"icon": Icons.check_room, "label": "Fashion", "color": Colors.purple},
    {"icon": Icons.phone_android, "label": "Elektronik", "color": Colors.blue},
  ];

  // Simulasi Data Produk dari Toko-Toko Seller (Firestore Simulasi)
  final List<Map<String, dynamic>> dummyProducts = [
    {
      "nama": "Sepatu Sneakers Olahraga Pria Casual Sport",
      "harga": "Rp 125.000",
      "toko": "Gacoan Store",
      "jarak": "1.2 km",
      "foto": "https://unsplash.com"
    },
    {
      "nama": "Headphone Wireless Bluetooth Bass Premium",
      "harga": "Rp 249.000",
      "toko": "Budi Elektronik",
      "jarak": "3.5 km",
      "foto": "https://unsplash.com"
    },
    {
      "nama": "Jam Tangan Pria Mewah Anti Air Original",
      "harga": "Rp 185.000",
      "toko": "Arloji Sentra",
      "jarak": "0.5 km",
      "foto": "https://unsplash.com"
    },
    {
      "nama": "Tas Ransel BackPack Laptop Sekolah & Kerja",
      "harga": "Rp 99.000",
      "toko": "Eiger Mandiri",
      "jarak": "2.1 km",
      "foto": "https://unsplash.com"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              // 1. HEADER MODEL SHOPEE (PENCARIAN & NOTIFIKASI)
              SliverAppBar(
                backgroundColor: Colors.blue.shade700,
                floating: true,
                pinned: true,
                elevation: 0,
                title: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.only(top: 8),
                      border: InputBorder.none,
                      hintText: "Cari produk, toko, atau area terdekat...",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ];
          },
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. BANNER PROMO BERGERAK AUTOMATIS (CAROUSEL)
                const SizedBox(height: 10),
                CarouselSlider(
                  options: CarouselOptions(
                    height: 150.0,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    viewportFraction: 0.92,
                    aspectRatio: 16 / 9,
                  ),
                  items: imgBannerList.map((imageUrl) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),

                // 3. BARIS MENU KATEGORI (SHOPEE STYLE)
                const SizedBox(height: 20),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: categories[index]['color'].withValues(alpha: 0.1),
                              child: Icon(categories[index]['icon'], color: categories[index]['color'], size: 26),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              categories[index]['label'],
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // SECTION TITLE: PRODUK REKOMENDASI COD
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      Text(
                        "Rekomendasi Terdekat (COD)",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text("Lihat Semua", style: TextStyle(color: Colors.blue)),
                      ),
                    ],
                  ),
                ),

                // 4. GRID PRODUK DUA KOLOM (RAMAI DAN PADAT)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: dummyProducts.length,
                    itemBuilder: (context, index) {
                      final product = dummyProducts[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Foto Produk
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  image: DecorationImage(
                                    image: NetworkImage(product['foto']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nama Barang
                                  Text(
                                    product['nama'],
                                    maxLines: 2,
