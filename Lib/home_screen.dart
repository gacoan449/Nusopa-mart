import 'package:flutter/material.dart';
import 'package:carousel_slider_plus/carousel_slider_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../services/jarak_service.dart'; // Utilitas hitung jarak km bumi bulat
import 'keranjang_screen.dart';       // Menghubungkan tombol ikon keranjang belanja

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String kueriPencarian = "";
  Position? posisiPembeli;

  // Gambar Spanduk Promo Admin (Gunakan tautan gambar asli agar tidak pecah/eror)
  final List<String> imgBannerList = [
    'https://unsplash.com', // Banner belanja
    'https://unsplash.com', // Banner promo promo
  ];

  // Daftar Kategori Shopee Style
  final List<Map<String, dynamic>> categories = [
    {"icon": Icons.live_tv, "label": "Shopee Live", "color": Colors.red},
    {"icon": Icons.local_shipping, "label": "Bisa COD", "color": Colors.green},
    {"icon": Icons.flash_on, "label": "Flash Sale", "color": Colors.orange},
    {"icon": Icons.check_room, "label": "Fashion", "color": Colors.purple},
    {"icon": Icons.phone_android, "label": "Elektronik", "color": Colors.blue},
  ];

  @override
  void initState() {
    super.initState();
    _tangkapGpsPembeli();
  }

  // Fungsi mengaktifkan GPS pembeli secara otomatis saat membuka aplikasi
  void _tangkapGpsPembeli() async {
    Position? posisi = await JarakService.ambilLokasiSekarang();
    if (posisi != null) {
      setState(() {
        posisiPembeli = posisi;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              // 1. HEADER MODEL SHOPEE (PENCARIAN NYATA & NOTIFIKASI)
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
                    onChanged: (value) {
                      setState(() {
                        kueriPencarian = value.toLowerCase(); // Filter text dinamis
                      });
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.only(top: 8),
                      border: InputBorder.none,
                      hintText: "Cari produk, toko, atau area terdekat...",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                    ),
                  ),
                ),
                actions: [
                  // TERHUBUNG NYATA: Membuka Halaman Keranjang Belanja COD Anda
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const KeranjangScreen()),
                      );
                    },
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
                // 2. BANNER PROMO BERGERAK OTOMATIS (CAROUSEL)
                const SizedBox(height: 10),
                CarouselSlider(
                  options: CarouselOptions(
                    height: 140.0,
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
                              backgroundColor: categories[index]['color'].withAlpha(26),
                              child: Icon(categories[index]['icon'], color: categories[index]['color'], size: 24),
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

                // TITLE BAR FILTER ALGORITMA REKOMENDASI
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      Text(
                        "Rekomendasi Teratas Bintang 5 ⭐",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                      const Text("Urutan Rating Terbaik", style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),

                // 4. GRID PRODUK DUA KOLOM DARI FIRESTORE + ALGORITMA FILTER BINTANG 5 & JARAK RADIUS GPS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: StreamBuilder<QuerySnapshot>(
                    // ALGORITMA UTAMA: Urutkan produk dari data awan berdasarkan rating/bintang 5 teratas
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .orderBy('rating', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Text('Belum ada barang dagangan yang dipajang seller.', style: TextStyle(color: Colors.grey)),
                          ),
                        );
                      }

                      // Membaca list dokumen asli dari Firestore
                      var productDocs = snapshot.data!.docs;

                      // Melakukan penyaringan kata kunci pencarian teks di beranda jika ada input teks
                      if (kueriPencarian.isNotEmpty) {
                        productDocs = productDocs.where((doc) {
                          String namaProd = (doc['nama_produk'] ?? '').toString().toLowerCase();
                          return namaProd.contains(kueriPencarian);
                        }).toList();
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.70,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: productDocs.length,
                        itemBuilder: (context, index) {
                          var pData = productDocs[index].data() as Map<String, dynamic>;
                          
