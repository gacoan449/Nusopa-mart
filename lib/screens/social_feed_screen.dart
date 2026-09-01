import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/social_widgets.dart';

/// Beranda sosial Nusopa.Mart.
/// Rekber tetap menjadi aksi transaksi, bukan menggantikan marketplace lama.
class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});
  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final postController = TextEditingController();
  bool liked = false;

  @override
  void dispose() { postController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SocialTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 12,
        title: Text('Nusopa', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: SocialTheme.blue)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded), tooltip: 'Notifikasi'),
          IconButton(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline_rounded), tooltip: 'Chat'),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 28),
        children: [
          _searchBar(),
          const SizedBox(height: 10),
          _createPost(),
          const SizedBox(height: 10),
          _post(
            name: 'Rizky Gadget', time: '15 menit',
            text: 'Ada yang mencari HP gaming bekas? Kondisi mulus, bisa cek detail produk. Transaksi tersedia lewat Rekber Nusopa.Mart.',
            images: const ['https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=900'], likes: 24, comments: 6,
          ),
          const SizedBox(height: 10),
          _post(
            name: 'Dapur Bu Sari', time: '1 jam',
            text: 'Ready paket sambal rumahan. Bisa kirim hari ini. Silakan lihat produk dan gunakan Rekber untuk transaksi lebih aman.',
            images: const ['https://images.unsplash.com/photo-1601050690597-df0568f70950?w=900', 'https://images.unsplash.com/photo-1547592180-85f173990554?w=900'], likes: 41, comments: 9,
          ),
        ],
      ),
    );
  }

  Widget _searchBar() => SocialCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(children: [
      const Icon(Icons.search, color: SocialTheme.muted),
      const SizedBox(width: 8),
      Expanded(child: Text('Cari orang, postingan, produk, atau grup...', style: GoogleFonts.inter(color: SocialTheme.muted, fontSize: 12))),
    ]),
  );

  Widget _createPost() => SocialCard(child: Column(children: [
    Row(children: [
      const SocialAvatar(imageUrl: '', radius: 21), const SizedBox(width: 10),
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: SocialTheme.background, borderRadius: BorderRadius.circular(24)),
        child: Text('Apa yang Anda pikirkan atau ingin Anda cari?', style: GoogleFonts.inter(color: SocialTheme.muted, fontSize: 12)),
      )),
    ]),
    const Divider(height: 22),
    Row(children: [
      Expanded(child: _createAction(Icons.photo_library_outlined, 'Foto', () {})),
      Expanded(child: _createAction(Icons.sell_outlined, 'Tag Produk', () {})),
    ]),
  ]));

  Widget _createAction(IconData icon, String label, VoidCallback onTap) => TextButton.icon(
    onPressed: onTap, icon: Icon(icon, color: SocialTheme.blue, size: 20),
    label: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: SocialTheme.text)),
  );

  Widget _post({required String name, required String time, required String text, required List<String> images, required int likes, required int comments}) => SocialCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SocialPostHeader(avatar: '', name: name, time: time),
      const SizedBox(height: 2),
      Text(text, style: GoogleFonts.inter(fontSize: 13, height: 1.45, color: SocialTheme.text)),
      if (images.isNotEmpty) ...[const SizedBox(height: 12), SocialImageGrid(images: images)],
      const SizedBox(height: 10),
      const DecoratedBox(
        decoration: BoxDecoration(color: Color(0xFFEAF3FF), borderRadius: BorderRadius.all(Radius.circular(10))),
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.shield_outlined, size: 16, color: SocialTheme.blue), SizedBox(width: 5), Text('Produk dapat dibeli lewat Rekber', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: SocialTheme.blue))]),
      ),
      const SizedBox(height: 8),
      RekberButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alur checkout Rekber siap dihubungkan ke CheckoutScreen.')))),
      SocialInteractionBar(likes: liked ? likes + 1 : likes, comments: comments, onLike: () => setState(() => liked = !liked), onComment: () {}, onShare: () {}),
    ]),
  );
}
