import 'package:flutter/material.dart';
import 'package:carousel_slider_plus/carousel_slider_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/jarak_service.dart';
import 'keranjang_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String pencarian = "";

  Position? posisiPembeli;

  final List<String> banner = [
    "https://picsum.photos/900/300?1",
    "https://picsum.photos/900/300?2",
    "https://picsum.photos/900/300?3",
  ];

  final List<Map<String, dynamic>> menu = [
    {
      "icon": Icons.live_tv,
      "judul": "Live",
      "warna": Colors.red,
    },
    {
      "icon": Icons.shopping_bag,
      "judul": "Belanja",
      "warna": Colors.blue,
    },
    {
      "icon": Icons.local_shipping,
      "judul": "COD",
      "warna": Colors.orange,
    },
    {
      "icon": Icons.store,
      "judul": "Toko",
      "warna": Colors.green,
    },
    {
      "icon": Icons.support_agent,
      "judul": "CS",
      "warna": Colors.purple,
    },
    {
      "icon": Icons.confirmation_number,
      "judul": "Tiket",
      "warna": Colors.indigo,
    },
  ];
  @override
  void initState() {
    super.initState();
    _ambilLokasi();
  }

  Future<void> _ambilLokasi() async {
    final posisi = await JarakService.ambilLokasiSekarang();

    if (!mounted) return;

    setState(() {
      posisiPembeli = posisi;
    });
  }

  Future<void> _hubungiAdmin() async {
    final url = Uri.parse(
      "https://wa.me/6281234567890?text=Halo Admin Nusopa Mart",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  void _bukaKeranjang() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const KeranjangScreen(),
      ),
    );
  }

  Widget _menuItem(Map<String, dynamic> item) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (item["judul"] == "CS") {
          _hubungiAdmin();
        }
      },
      child: SizedBox(
        width: 75,
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: (item["warna"] as Color).withOpacity(0.12),
              child: Icon(
                item["icon"],
                color: item["warna"],
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item["judul"],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xff2563EB),
        foregroundColor: Colors.white,

        title: Container(
          height: 42,

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),

          child: TextField(
            onChanged: (value) {
              setState(() {
                pencarian = value.toLowerCase();
              });
            },

            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "Cari produk atau toko...",
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),

        actions: [

          IconButton(
            onPressed: _bukaKeranjang,
            icon: const Icon(Icons.shopping_cart_outlined),
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),

        ],
      ),

      body: SingleChildScrollView(

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 12),

            CarouselSlider(
              options: CarouselOptions(
                height: 170,
                autoPlay: true,
                viewportFraction: 0.95,
                enlargeCenterPage: true,
              ),

              items: banner.map((item) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    item,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [

                  const Text(
                    "Menu Nusopa Mart",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Text(
                      posisiPembeli == null
                          ? "Mencari Lokasi..."
                          : "COD Aktif",
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 95,

              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),

                itemCount: menu.length,

                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: _menuItem(menu[index]),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),

              child: Text(
                "Rekomendasi Untuk Anda",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("products")
                  .snapshots(),

              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(25),
                    child: Center(
                      child: Text(
                        "Belum ada produk.",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }

                var docs = snapshot.data!.docs;

                if (pencarian.isNotEmpty) {
                  docs = docs.where((e) {
                    final data =
                        e.data() as Map<String, dynamic>;

                    final nama =
                        (data["nama_produk"] ?? "")
                            .toString()
                            .toLowerCase();

                    return nama.contains(pencarian);
                  }).toList();
                }

                return GridView.builder(

                  shrinkWrap: true,

                  physics:
                      const NeverScrollableScrollPhysics(),

                  padding: const EdgeInsets.all(12),

                  itemCount: docs.length,

                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(

                    crossAxisCount: 2,

                    childAspectRatio: 0.70,

                    crossAxisSpacing: 10,

                    mainAxisSpacing: 10,

                  ),

                  itemBuilder: (context, index) {

                    final data =
                        docs[index].data()
                            as Map<String, dynamic>;

                    return Card(

                      elevation: 2,

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Column(

                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          Expanded(

                            child: ClipRRect(

                              borderRadius:
                                  const BorderRadius.vertical(
                                top: Radius.circular(14),
                              ),

                              child: Image.network(

                                data["gambar"] ??
                                    "https://picsum.photos/300",

                                width: double.infinity,

                                fit: BoxFit.cover,

                                errorBuilder:
                                    (context, error, stackTrace) {

                                  return Container(

                                    color: Colors.grey.shade200,

                                    child: const Center(

                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                      ),

                                    ),

                                  );

                                },

                              ),

                            ),

                          ),

                          Padding(

                            padding: const EdgeInsets.all(8),

                            child: Column(

                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [

                                Text(

                                  data["nama_produk"] ??
                                      "Produk",

                                  maxLines: 2,

                                  overflow:
                                      TextOverflow.ellipsis,

                                  style: const TextStyle(

                                    fontWeight: FontWeight.bold,

                                    fontSize: 14,

                                  ),

                                ),

                                const SizedBox(height: 6),

                                Text(

                                  "Rp ${data["harga"] ?? 0}",

                                  style: const TextStyle(

                                    color: Colors.blue,

                                    fontWeight: FontWeight.bold,

                                    fontSize: 15,

                                  ),

                                ),

                                const SizedBox(height: 4),
                                Row(

                                  children: [

                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 15,
                                    ),

                                    const SizedBox(width: 4),

                                    Expanded(

                                      child: Text(

                                        data["kota"] ??
                                            "Lokasi",

                                        maxLines: 1,

                                        overflow:
                                            TextOverflow.ellipsis,

                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 12,
                                        ),

                                      ),

                                    ),

                                  ],

                                ),

                                const SizedBox(height: 8),

                                SizedBox(

                                  width: double.infinity,

                                  child: ElevatedButton(

                                    onPressed: () {},

                                    style: ElevatedButton.styleFrom(

                                      backgroundColor:
                                          const Color(0xff2563EB),

                                      foregroundColor:
                                          Colors.white,

                                      shape:
                                          RoundedRectangleBorder(

                                        borderRadius:
                                            BorderRadius.circular(10),

                                      ),

                                    ),

                                    child: const Text(
                                      "Lihat Produk",
                                    ),

                                  ),

                                ),
                                ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
