import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'chat_screen.dart';
import 'orders_screen.dart';
import 'product_detail_screen.dart';
import 'seller_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const blue = Color(0xFF126BFF);
  static const bg = Color(0xFFF4F8FF);

  int tab = 0;
  final search = TextEditingController();
  String query = '';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: TextField(
            controller: search,
            onChanged: (value) {
              setState(() => query = value.toLowerCase().trim());
            },
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, color: blue),
              hintText: 'Cari produk, toko, atau kategori...',
              hintStyle: GoogleFonts.inter(fontSize: 13),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        search.clear();
                        setState(() => query = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
            icon: const Icon(Icons.shopping_bag_outlined, color: blue),
            tooltip: 'Keranjang',
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatScreen()),
            ),
            icon: const Icon(Icons.headset_mic_rounded, color: blue),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: [
        _HomeContent(query: query),
        const OrdersScreen(),
        const ChatScreen(),
        const AccountScreen(),
      ][tab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab,
        onTap: (value) => setState(() => tab = value),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.headset_mic_outlined),
            activeIcon: Icon(Icons.headset_mic),
            label: 'Bantuan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Saya',
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  final String query;

  const _HomeContent({required this.query});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  static const blue = Color(0xFF126BFF);
  final page = PageController(viewportFraction: .92);

  @override
  void dispose() {
    page.dispose();
    super.dispose();
  }

  int val(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  String money(dynamic value) {
    final number = val(value);
    return 'Rp${number.toString().replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (_) => '.')}';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SizedBox(
                height: 165,
                child: PageView(
                  controller: page,
                  children: [
                    _banner(
                      'BELANJA AMAN DENGAN REKBER',
                      'Dana mengikuti alur transaksi Nusopa.Mart',
                      Icons.shield_outlined,
                    ),
                    _banner(
                      'JUAL BARANGMU',
                      'Upload foto, atur stok dan terima pesanan',
                      Icons.storefront_outlined,
                    ),
                    _banner(
                      'TRANSAKSI LEBIH TENANG',
                      'Gunakan bantuan Admin saat ada masalah',
                      Icons.verified_user_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _cat(
                    Icons.shield_outlined,
                    'Rekber',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    ),
                  ),
                  _cat(
                    Icons.local_fire_department_outlined,
                    'Promo',
                    () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Promo resmi akan tampil saat tersedia.'),
                      ),
                    ),
                  ),
                  _cat(
                    Icons.inventory_2_outlined,
                    'Pesanan',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrdersScreen()),
                    ),
                  ),
                  _cat(
                    Icons.add_business_outlined,
                    'Jual',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SellerDashboard()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: blue,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Color(0xFFFFC107), size: 30),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FLASH PROMO',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Promo dan voucher resmi dari Admin',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _FlashPromoTimer(),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _voucher('🎁 VOUCHER', 'Promo pengguna baru'),
                  const SizedBox(width: 10),
                  _voucher('🛡️ REKBER', 'Perlindungan transaksi'),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Text(
                'REKOMENDASI UNTUK KAMU',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: blue,
                ),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('active', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 34),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: _empty(
                    'Produk belum dapat dimuat',
                    Icons.cloud_off_outlined,
                  ),
                );
              }

              var docs = snapshot.data?.docs ?? const [];
              docs = docs.where((document) {
                final data = document.data();
                final name = (data['name'] ?? data['productName'] ?? '').toString();
                final image = (data['imageUrl'] ?? data['image'] ?? '').toString();
                final seller = (data['sellerId'] ?? '').toString();
                final price = val(data['price'] ?? data['productPrice']);
                final searchable =
                    '$name ${data['category'] ?? ''} ${data['storeName'] ?? ''}'
                        .toLowerCase();

                return name.trim().isNotEmpty &&
                    image.trim().isNotEmpty &&
                    seller.trim().isNotEmpty &&
                    price > 0 &&
                    (widget.query.isEmpty || searchable.contains(widget.query));
              }).toList();

              if (docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: _empty(
                    widget.query.isEmpty
                        ? 'Belum ada produk aktif'
                        : 'Produk tidak ditemukan',
                    Icons.inventory_2_outlined,
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: .61,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _product(context, docs[index]),
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 45)),
        ],
      ),
    );
  }

  Widget _product(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final name = (data['name'] ?? data['productName'] ?? 'Produk').toString();
    final image = (data['imageUrl'] ?? data['image'] ?? '').toString();

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            productId: document.id,
            product: data,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.network(
                image,
                width: double.infinity,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image_outlined, size: 34),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    money(data['price'] ?? data['productPrice']),
                    style: GoogleFonts.inter(
                      color: blue,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '⭐ ${(data['rating'] ?? 5.0)}  •  Terjual ${(data['sold'] ?? 0)}',
                    style: GoogleFonts.inter(fontSize: 9, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '🛡 Rekber Aman',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF16803A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _banner(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [blue, Color(0xFF62B6FF)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(icon, color: Colors.white, size: 42),
        ],
      ),
    );
  }

  Widget _cat(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: blue, size: 24),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _voucher(String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: blue.withValues(alpha: .1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                color: blue,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(34),
      child: Column(
        children: [
          Icon(icon, size: 46, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          const Text('Produk seller yang aktif akan tampil di sini.'),
        ],
      ),
    );
  }
}

class _FlashPromoTimer extends StatefulWidget {
  const _FlashPromoTimer();

  @override
  State<_FlashPromoTimer> createState() => _FlashPromoTimerState();
}

class _FlashPromoTimerState extends State<_FlashPromoTimer> {
  Timer? timer;
  int seconds = 5124;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && seconds > 0) {
        setState(() => seconds--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final remaining = (seconds % 60).toString().padLeft(2, '0');

    return Text(
      '$hours:$minutes:$remaining',
      style: GoogleFonts.inter(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
