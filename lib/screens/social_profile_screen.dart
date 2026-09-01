import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_screen.dart';
import 'seller_dashboard.dart';
import 'orders_screen.dart';
import 'rekber_info_screen.dart';
import '../widgets/social_widgets.dart';

/// Profil sosial Facebook-style.
/// Fungsi Belanja, Pesanan, Toko dan Rekber ditempatkan di Profil, bukan Feed.
class SocialProfileScreen extends StatefulWidget {
  final String? userName;
  const SocialProfileScreen({super.key, this.userName});
  @override
  State<SocialProfileScreen> createState() => _SocialProfileScreenState();
}

class _SocialProfileScreenState extends State<SocialProfileScreen> {
  int tab = 0;
  bool following = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.userName ?? 'Pengguna Nusopa';
    return Scaffold(
      backgroundColor: SocialTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        actions: [IconButton(onPressed: () => _showAccountMenu(context), icon: const Icon(Icons.menu_rounded))],
      ),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _profileHeader(name)),
        SliverToBoxAdapter(child: Container(
          color: Colors.white,
          margin: const EdgeInsets.only(top: 82),
          child: Row(children: [
            SocialTab(label: 'Postingan Sosial', selected: tab == 0, onTap: () => setState(() => tab = 0)),
            SocialTab(label: 'Produk Jualan', selected: tab == 1, onTap: () => setState(() => tab = 1)),
          ]),
        )),
        SliverPadding(padding: const EdgeInsets.all(12), sliver: tab == 0 ? _posts() : _products()),
      ]),
    );
  }

  Widget _profileHeader(String name) => Container(
    color: Colors.white,
    child: Column(children: [
      Stack(clipBehavior: Clip.none, children: [
        SizedBox(height: 190, width: double.infinity, child: Image.network(
          'https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=1200', fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE7EEF9)),
        )),
        Positioned(left: 18, bottom: -48, child: Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const SocialAvatar(imageUrl: '', radius: 48),
        )),
      ]),
      Padding(padding: const EdgeInsets.fromLTRB(18, 58, 18, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w900, color: SocialTheme.text)),
        const SizedBox(height: 5),
        Text('Jual beli, berbagi, dan transaksi lebih aman bersama komunitas Nusopa.', style: GoogleFonts.inter(fontSize: 11, color: SocialTheme.muted, height: 1.4)),
        const SizedBox(height: 14),
        Row(children: [
          _stat('1.2K', 'Pengikut'), _stat('324', 'Mengikuti'), _stat('4.9 ★', 'Rating Rekber'),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => setState(() => following = !following), icon: Icon(following ? Icons.check : Icons.person_add_alt_1), label: Text(following ? 'Mengikuti' : 'Ikuti'))),
          const SizedBox(width: 8),
          Expanded(child: FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())), icon: const Icon(Icons.chat_bubble_outline), label: const Text('Kirim Pesan'))),
        ]),
      ])),
    ]),
  );

  Widget _stat(String value, String label) => Expanded(child: Column(children: [Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 9, color: SocialTheme.muted))]));

  Widget _posts() => SliverList(delegate: SliverChildListDelegate([
    SocialCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SocialPostHeader(avatar: '', name: 'Pengguna Nusopa', time: 'Hari ini'),
      const SizedBox(height: 6),
      const Text('Baru menemukan produk menarik. Kalau ada yang cari, bisa kita transaksi menggunakan Rekber.', style: TextStyle(fontSize: 13, height: 1.45)),
      const SizedBox(height: 10),
      SocialImageGrid(images: const ['https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=900']),
      SocialInteractionBar(likes: 32, comments: 5, onLike: () {}, onComment: () {}, onShare: () {}),
    ])),
    const SizedBox(height: 10),
    SocialCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SocialPostHeader(avatar: '', name: 'Pengguna Nusopa', time: 'Kemarin'),
      const Text('Terima kasih untuk teman-teman komunitas yang sudah membantu.', style: TextStyle(fontSize: 13, height: 1.45)),
      SocialInteractionBar(likes: 15, comments: 2, onLike: () {}, onComment: () {}, onShare: () {}),
    ])),
  ]));

  Widget _products() => SliverGrid(
    delegate: SliverChildBuilderDelegate((context, i) => SocialCard(padding: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.network('https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=900', width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined)))),
      Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Produk Aktif ${i + 1}', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12)),
        const SizedBox(height: 4),
        Text('Rp${250000 + i * 50000}', style: GoogleFonts.inter(color: SocialTheme.blue, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.shield_outlined, size: 15), label: const Text('Rekber'))),
      ])),
    ])), childCount: 4),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .68),
  );

  void _showAccountMenu(BuildContext context) {
    showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.receipt_long_outlined), title: const Text('Pesanan Saya'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()))),
      ListTile(leading: const Icon(Icons.storefront_outlined), title: const Text('Kelola Produk & Toko'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerDashboard()))),
      ListTile(leading: const Icon(Icons.shield_outlined), title: const Text('Rekber & Perlindungan Transaksi'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RekberInfoScreen()))),
    ])));
  }
}
