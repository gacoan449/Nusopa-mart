import 'package:flutter/material.dart';
import 'package:carousel_slider_plus/carousel_slider_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart'; // Untuk fitur hubungi CS via WhatsApp
import '../services/jarak_service.dart'; 
import 'keranjang_screen.dart';       

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String kueriPencarian = "";
  Position? posisiPembeli;
  
  // Simulasi jumlah tiket seller (Ganti dengan ambil data dari Firestore user/seller Anda)
  int jumlahTiketSeller = 8; 

  // Direct link gambar promo profesional (Anti-pecah/eror)
  final List<String> imgBannerList = [
    'https://unsplash.com', 
    'https://unsplash.com', 
  ];

  // Menu Kategori Shopee Style disesuaikan dengan fitur versi Anda
  final List<Map<String, dynamic>> categories = [
    {"icon": Icons.live_tv, "label": "Live Gratis", "color": Colors.red},
    {"icon": Icons.local_shipping, "label": "Khusus COD", "color": Colors.orange.shade800},
    {"icon": Icons.confirmation_number, "label": "Beli Tiket", "color": Colors.blue},
    {"icon": Icons.support_agent, "label": "Hubungi CS", "color": Colors.green},
    {"icon": Icons.storefront, "label": "Mulai Jual", "color": Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _tangkapGpsPembeli();
  }

  void _tangkapGpsPembeli() async {
    Position? posisi = await JarakService.ambilLokasiSekarang();
    if (posisi != null) {
      setState(() {
        posisiPembeli = posisi;
      });
    }
  }

  // Fungsi manual chat ke WA Anda untuk top up tiket atau komplain resi
  void _hubungiCsWhatsApp() async {
    const nomorFormat = "6281234567890"; // GANTI DENGAN NOMOR WA ANDA
    const pesan = "Halo Admin CS, saya ingin top up tiket seller / tanya seputar pengiriman.";
    final url = Uri.parse("https://wa.me{Uri.encodeComponent(pesan)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
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
              // HEADER PREMIUM ALA SHOPEE (ORANGE KHAS COD)
              SliverAppBar(
                backgroundColor: Colors.orange.shade800,
                floating: true,
                pinned: true,
                elevation: 1,
                title: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        kueriPencarian = value.toLowerCase(); 
                      });
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.only(top: 4),
                      border: InputBorder.none,
                      hintText: "Cari toko atau produk COD terdekat...",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                    ),
                  ),
                ),
                actions: [
                  // INDIKATOR TIKET SELLER (Fitur Unik Anda)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade900,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.confirmation_number, color: Colors.yellow, size: 14),
                          const SizedBox(width: 4),
                          Text("$jumlahTiketSeller Tkt", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const KeranjangScreen()),
                      );
                    },
                  ),
                ],
              ),
            ];
          },
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BANNER PROMO BERGERAK
                const SizedBox(height: 8),
                CarouselSlider(
                  options: CarouselOptions(
                    height: 130.0,
                    autoPlay: true,
                    viewportFraction: 1.0, // Full width ala shopee banner beranda
                  ),
                  items: imgBannerList.map((imageUrl) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // BARIS MENU KATEGORI SHOPEE STYLE
                const SizedBox(height: 15),
                SizedBox(
                  height: 85,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          if (categories[index]['label'] == "Beli Tiket" || categories[index]['label'] == "Hubungi CS") {
                            _hubungiCsWhatsApp();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 23,
                                backgroundColor: categories[index]['color'].withAlpha(26),
                                child: Icon(categories[index]['icon'], color: categories[index]['color'], size: 22),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                categories[index]['label'],
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.black80),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // SEPARATOR STRIP ABU-ABU KHAS SHOPEE
                Container(height: 8, color: Colors.grey.shade200),

                // TITLE BAR REKOMENDASI
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      Text(
                        "REKOMENDASI TERDEKAT COD",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                      ),
                      Text("Paling Sesuai", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ),

                // GRID PRODUK DUA KOLOM
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .orderBy('rating', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Center(child: Text('Eror: ${snapshot.error}'));
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Belum ada produk dari seller.')));
                      }

                      var productDocs = snapshot.data!.docs;

                      if (kueriPencarian.isNotEmpty) {
                        productDocs = productDocs.where((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          String namaProd = (data['nama_produk'] ?? '').toString().toLowerCase();
