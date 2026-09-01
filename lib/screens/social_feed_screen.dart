import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/social_widgets.dart';

/// Feed sosial utama: timeline komunitas, bukan katalog toko.
class SocialFeedScreen extends StatelessWidget {
  const SocialFeedScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SocialTheme.background,
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: Text('Nusopa', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: SocialTheme.blue)),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline_rounded)),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(10),
      children: [
        _searchBar(),
        const SizedBox(height: 10),
        _createPost(),
        const SizedBox(height: 10),
        _post('Rizky Gadget', '15 menit', 'Ada yang mencari HP gaming bekas? Kondisi mulus. Detail produk tersedia di profil penjual.', const ['https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=900'], 24, 6),
        const SizedBox(height: 10),
        _post('Dapur Bu Sari', '1 jam', 'Ready paket sambal rumahan. Bisa kirim hari ini dan transaksi aman menggunakan Rekber Nusopa.', const ['https://images.unsplash.com/photo-1601050690597-df0568f70950?w=900', 'https://images.unsplash.com/photo-1547592180-85f173990554?w=900'], 41, 9),
      ],
    ),
  );

  Widget _searchBar() => SocialCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    child: Row(children: [
      const Icon(Icons.search, color: SocialTheme.muted),
      const SizedBox(width: 8),
      Expanded(child: Text('Cari orang, postingan, produk, atau grup...', style: GoogleFonts.inter(color: SocialTheme.muted, fontSize: 12))),
    ]),
  );

  Widget _createPost() => SocialCard(child: Column(children: [
    Row(children: [
      const SocialAvatar(imageUrl: '', radius: 21),
      const SizedBox(width: 10),
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: SocialTheme.background, borderRadius: BorderRadius.circular(24)),
        child: Text('Apa yang Anda pikirkan atau ingin Anda cari?', style: GoogleFonts.inter(color: SocialTheme.muted, fontSize: 12)),
      )),
    ]),
    const Divider(height: 22),
    Row(children: [
      Expanded(child: TextButton.icon(onPressed: () {}, icon: const Icon(Icons.photo_library_outlined, color: SocialTheme.blue), label: const Text('Foto'))),
      Expanded(child: TextButton.icon(onPressed: () {}, icon: const Icon(Icons.sell_outlined, color: SocialTheme.blue), label: const Text('Tag Produk'))),
    ]),
  ]));

  Widget _post(String name, String time, String text, List<String> images, int likes, int comments) => SocialCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SocialPostHeader(avatar: '', name: name, time: time),
      const SizedBox(height: 2),
      Text(text, style: GoogleFonts.inter(fontSize: 13, height: 1.45, color: SocialTheme.text)),
      if (images.isNotEmpty) ...[const SizedBox(height: 12), SocialImageGrid(images: images)],
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: const Color(0xFFEAF3FF), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.shield_outlined, size: 16, color: SocialTheme.blue),
          const SizedBox(width: 5),
          Text('Produk dapat dibeli lewat Rekber', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: SocialTheme.blue)),
        ]),
      ),
      const SizedBox(height: 8),
      RekberButton(onPressed: () {}),
      SocialInteractionBar(likes: likes, comments: comments, onLike: () {}, onComment: () {}, onShare: () {}),
    ]),
  );
}
