import 'package:flutter/material.dart';

void main() => runApp(const NusopaMartApp());

const _brand = Color(0xFF146B4A);
const _cream = Color(0xFFF7F7F0);

class NusopaMartApp extends StatelessWidget {
  const NusopaMartApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Nusopa Mart',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _brand),
      scaffoldBackgroundColor: _cream,
      appBarTheme: const AppBarTheme(backgroundColor: _cream, foregroundColor: _brand),
    ),
    home: const MarketplaceHome(),
  );
}

class MarketProduct {
  const MarketProduct(this.name, this.category, this.price, this.unit, this.emoji, {this.badge});
  final String name, category, unit, emoji;
  final int price;
  final String? badge;
}

const _products = <MarketProduct>[
  MarketProduct('Beras premium', 'Sembako', 72000, '5 kg', '🌾', badge: 'Pilihan warga'),
  MarketProduct('Telur ayam', 'Ayam & Telur', 29000, 'kg', '🥚'),
  MarketProduct('Ayam potong segar', 'Ayam & Telur', 36000, 'ekor', '🍗', badge: 'Segar hari ini'),
  MarketProduct('Cabai merah', 'Sayur & Buah', 32000, 'kg', '🌶️'),
  MarketProduct('Pisang kepok', 'Sayur & Buah', 14000, 'sisir', '🍌'),
  MarketProduct('Minyak goreng', 'Sembako', 18000, 'liter', '🫗'),
  MarketProduct('Kabel data USB-C', 'Elektronik', 25000, 'pcs', '🔌'),
  MarketProduct('Lampu LED', 'Elektronik', 19000, 'pcs', '💡'),
];
const _categories = ['Semua', 'Sembako', 'Sayur & Buah', 'Ayam & Telur', 'Elektronik'];

class MarketplaceHome extends StatefulWidget {
  const MarketplaceHome({super.key});
  @override
  State<MarketplaceHome> createState() => _MarketplaceHomeState();
}

class _MarketplaceHomeState extends State<MarketplaceHome> {
  String _category = 'Semua', _query = '';
  int _tab = 0;
  final Map<String, int> _cart = {};
  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);
  int get _cartTotal => _products.where((p) => _cart.containsKey(p.name))
      .fold(0, (sum, p) => sum + p.price * _cart[p.name]!);

  @override
  Widget build(BuildContext context) {
    final filtered = _products.where((p) =>
      (_category == 'Semua' || p.category == _category) &&
      p.name.toLowerCase().contains(_query.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.storefront_rounded, size: 29), SizedBox(width: 8),
          Text('nusopa', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1)),
          Text('.mart', style: TextStyle(fontWeight: FontWeight.w400)),
        ]),
        actions: [
          IconButton(tooltip: 'Keranjang', onPressed: _showCart,
            icon: Badge(label: Text(_cartCount.toString()), child: const Icon(Icons.shopping_bag_outlined))),
          const SizedBox(width: 8),
        ],
      ),
      body: _tab == 0 ? _buildMarket(filtered) : _buildOtherTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Belanja'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Pesanan'),
          NavigationDestination(icon: Icon(Icons.delivery_dining_outlined), label: 'Kurir'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Akun'),
        ],
      ),
    );
  }

  Widget _buildMarket(List<MarketProduct> products) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_brand, Color(0xFF26845E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24)),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BELANJA DEKAT,\nDUKUNG USAHA LOKAL', style: TextStyle(color: Colors.white, fontSize: 23, height: 1.15, fontWeight: FontWeight.w900)),
          SizedBox(height: 10),
          Text('Sembako, hasil tani, ayam segar, dan kebutuhan harian dalam satu tempat.', style: TextStyle(color: Colors.white, height: 1.35)),
          SizedBox(height: 14),
          Row(children: [
            Icon(Icons.location_on_outlined, color: Colors.white, size: 18), SizedBox(width: 5),
            Text('Melayani Jawa Tengah • bertahap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
      const SizedBox(height: 18),
      TextField(
        onChanged: (value) => setState(() => _query = value),
        decoration: InputDecoration(
          hintText: 'Cari produk atau kebutuhan…', prefixIcon: const Icon(Icons.search),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
      ),
      const SizedBox(height: 18),
      const Text('Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      SizedBox(height: 42, child: ListView.separated(
        scrollDirection: Axis.horizontal, itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final category = _categories[i];
          return ChoiceChip(
            label: Text(category), selected: _category == category,
            onSelected: (_) => setState(() => _category = category),
            selectedColor: const Color(0xFFD5EBDD),
            labelStyle: TextStyle(color: _category == category ? _brand : Colors.black87, fontWeight: FontWeight.w600));
        })),
      const SizedBox(height: 18),
      Row(children: [
        const Expanded(child: Text('Pilihan untukmu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
        Text(products.length.toString() + ' produk', style: const TextStyle(color: Colors.black54)),
      ]),
      const SizedBox(height: 12),
      if (products.isEmpty)
        const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Produk tidak ditemukan. Coba kata kunci lain.')))
      else
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 238),
          itemBuilder: (context, index) => _productCard(products[index])),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.store_mall_directory_outlined, color: _brand, size: 28), SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Punya toko atau usaha?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            SizedBox(height: 4),
            Text('Penjual lokal dapat mendaftar. Rencana komisi platform untuk penjual pihak ketiga: 3%, sesuai ketentuan yang ditetapkan admin.'),
          ])),
        ]),
      ),
    ],
  );

  Widget _productCard(MarketProduct product) {
    final count = _cart[product.name] ?? 0;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8E9E2))),
      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: const Color(0xFFF0F5ED), borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(product.emoji, style: const TextStyle(fontSize: 48))))),
        if (product.badge != null) ...[
          const SizedBox(height: 8),
          Text(product.badge!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: _brand, fontWeight: FontWeight.w700)),
        ] else const SizedBox(height: 8),
        Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text('Rp' + _money(product.price) + ' / ' + product.unit, maxLines: 1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, height: 34, child: FilledButton(
          onPressed: () => setState(() => _cart[product.name] = count + 1),
          style: FilledButton.styleFrom(backgroundColor: _brand, padding: EdgeInsets.zero),
          child: Text(count == 0 ? '+ Keranjang' : 'Tambah lagi (' + count.toString() + ')', style: const TextStyle(fontSize: 12)))),
      ])),
    );
  }

  Widget _buildOtherTab() {
    final descriptions = [
      '', 'Riwayat pesanan, status pembayaran, dan pelacakan akan tampil setelah backend dihubungkan.',
      'Mode kurir akan memuat tugas, lokasi GPS, peta, dan navigasi Google Maps setelah integrasi lokasi.',
      'Profil pengguna, alamat, pendaftaran penjual, dan pengaturan akun akan tersedia di sini.',
    ];
    final icons = [Icons.storefront, Icons.receipt_long, Icons.delivery_dining, Icons.person];
    final titles = ['Belanja', 'Pesanan', 'Kurir', 'Akun'];
    return Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icons[_tab], size: 64, color: _brand), const SizedBox(height: 16),
      Text(titles[_tab], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Text(descriptions[_tab], textAlign: TextAlign.center, style: const TextStyle(height: 1.4, color: Colors.black54)),
      if (_tab == 2) ...[
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigasi aktif setelah lokasi tujuan dan integrasi kurir tersedia.'))),
          icon: const Icon(Icons.navigation_outlined), label: const Text('Navigasi kurir')),
      ],
    ])));
  }

  void _showCart() {
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (context) => StatefulBuilder(builder: (context, modalSetState) {
        final items = _products.where((p) => (_cart[p.name] ?? 0) > 0).toList();
        return Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), child: SafeArea(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Keranjang (' + _cartCount.toString() + ')', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            if (items.isEmpty) const Padding(padding: EdgeInsets.all(18), child: Center(child: Text('Keranjang masih kosong.')))
            else ...items.map((p) => ListTile(
              contentPadding: EdgeInsets.zero, leading: Text(p.emoji, style: const TextStyle(fontSize: 28)),
              title: Text(p.name), subtitle: Text('Rp' + _money(p.price) + ' × ' + _cart[p.name].toString()),
              trailing: IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () {
                setState(() {
                  final next = (_cart[p.name] ?? 0) - 1;
                  if (next <= 0) { _cart.remove(p.name); } else { _cart[p.name] = next; }
                });
                modalSetState(() {});
              }))),
            const Divider(),
            Row(children: [
              const Expanded(child: Text('Subtotal (belum termasuk ongkir)', style: TextStyle(fontWeight: FontWeight.w700))),
              Text('Rp' + _money(_cartTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: items.isEmpty ? null : () {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Keranjang demo. Checkout perlu backend, alamat, ongkir, dan verifikasi pembayaran.')));
              },
              child: const Text('Lanjut checkout'))),
          ])));
      }),
    );
  }
}

String _money(int value) {
  final digits = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  return out.toString();
}
