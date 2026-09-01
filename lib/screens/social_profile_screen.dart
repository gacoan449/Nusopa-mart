import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_screen.dart';
import 'seller_dashboard.dart';
import 'orders_screen.dart';
import 'rekber_info_screen.dart';
import '../widgets/social_widgets.dart';

/// Profil sosial: identitas pengguna di depan, fungsi akun/Rekber di bawah tab/menu.
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
      body: CustomScrollView(slivers: [
        SliverAppBar(pinned: true, expandedHeight: 265, backgroundColor: Colors.white, surfaceTintColor: Colors.white, title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w800)), flexibleSpace: FlexibleSpaceBar(background: _profileHeader(name))),
        SliverToBoxAdapter(child: Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(12, 8, 12, 0), child: Row(children: [
          SocialTab(label: 'Postingan Sosial', selected: tab == 0, onTap: () => setState(() => tab = 0)),
          SocialTab(label: 'Produk Jualan', selected: tab == 1, onTap: () => setState(() => tab = 1)),
        ]))),
        SliverPadding(padding: const EdgeInsets.all(12), sliver: tab == 0 ? _posts() : _products()),
      ]),
    );
  }

  Widget _profileHeader(String name) => Container(
    decoration: const BoxDecoration(color: Color(0xFFE7EEF9)),
    child: Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(child: Image.network('https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=1200', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
      Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 100, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xCC000000)])))),
      Positioned(left: 18, bottom: -36, child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const SocialAvatar(imageUrl: '', radius: 42))),
      Positioned(left: 118, right: 12, bottom: 10, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), Text('Jual beli, berbagi, dan transaksi lebih aman.', style: GoogleFonts.inter(color: Colors.white70, fontSize: 10))])),
      Positioned(left: 14, right: 14, bottom: -82, child: Container(padding: const EdgeInsets.only(left: 110, top: 6), child: Row(children: [
        Expanded(child: Text.rich(TextSpan(children: [TextSpan(text: '1.2K\n', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14)), TextSpan(text: 'Pengikut', style: GoogleFonts.inter(fontSize: 9, color: SocialTheme.muted))]))),
        Expanded(child: Text.rich(TextSpan(children: [TextSpan(text: '324\n', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14)), TextSpan(text: 'Mengikuti', style: GoogleFonts.inter(fontSize: 9, color: SocialTheme.muted))]))),
        Expanded(child: Text.rich(TextSpan(children: [TextSpan(text: '4.9 ★\n', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14)), TextSpan(text: 'Rating Rekber', style: GoogleFonts.inter(fontSize: 9, color: SocialTheme.muted))]))),
      ]))),
      Positioned(right: 14, bottom: -126, child: Row(children: [OutlinedButton.icon(onPressed: () => setState(() => following = !following), icon: Icon(following ? Icons.check : Icons.person_add_alt_1), label: Text(following ? 'Mengikuti' : 'Ikuti')), const SizedBox(width: 8), FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())), icon: const Icon(Icons.chat_bubble_outline), label: const Text('Kirim Pesan'))])),
    ],
  );

  SliverGrid _posts() => SliverGrid.count(crossAxisCount: 1, mainAxisSpacing: 10, childAspectRatio: 1.18, children: [
    SocialCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SocialPostHeader(avatar: '', name: 'Pengguna Nusopa', time: 'Hari ini'), const Text('Baru menemukan produk menarik. Kalau ada yang cari, bisa kita transaksi menggunakan Rekber.', style: TextStyle(fontSize: 13, height: 1.45)), const SizedBox(height: 10), SocialImageGrid(images: const ['https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=900']), SocialInteractionBar(likes: 32, comments: 5, onLike: () {}, onComment: () {}, onShare: () {})])),
    SocialCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SocialPostHeader(avatar: '', name: 'Pengguna Nusopa', time: 'Kemarin'), const Text('Terima kasih untuk teman-teman komunitas yang sudah membantu.', style: TextStyle(fontSize: 13, height: 1.45)), SocialInteractionBar(likes: 15, comments: 2, onLike: () {}, onComment: () {}, onShare: () {})])),
  ];

  SliverGrid _products() => SliverGrid.count(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .68, children: List.generate(4, (i) => SocialCard(padding: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.network('https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=900', width: double.infinity, fit: BoxFit.cover))), Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Produk Aktif ${i + 1}', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 4), Text('Rp${(250000 + i * 50000).toString()}', style: GoogleFonts.inter(color: SocialTheme.blue, fontWeight: FontWeight.w900)), const SizedBox(height: 7), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.shield_outlined, size: 15), label: const Text('Rekber')))]))]))));

  Widget _menu(BuildContext context) => Column(children: [
    ListTile(leading: const Icon(Icons.receipt_long_outlined), title: const Text('Pesanan Saya'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()))),
    ListTile(leading: const Icon(Icons.storefront_outlined), title: const Text('Kelola Produk & Toko'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerDashboard()))),
    ListTile(leading: const Icon(Icons.shield_outlined), title: const Text('Aturan & Rekber'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RekberInfoScreen()))),
  ]);
}
