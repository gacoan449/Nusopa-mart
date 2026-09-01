import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warna dan gaya bersama untuk modul sosial Nusopa.Mart.
class SocialTheme {
  static const blue = Color(0xFF126BFF);
  static const background = Color(0xFFF4F7FB);
  static const text = Color(0xFF172033);
  static const muted = Color(0xFF6B7485);
  static const border = Color(0xFFE5E9F0);
}

/// Avatar reusable dengan fallback ikon pengguna.
class SocialAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final bool online;

  const SocialAvatar({super.key, required this.imageUrl, this.radius = 22, this.online = false});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFEAF1FF),
        backgroundImage: imageUrl.trim().isEmpty ? null : NetworkImage(imageUrl),
        onBackgroundImageError: imageUrl.trim().isEmpty ? null : (_, __) {},
        child: imageUrl.trim().isEmpty ? Icon(Icons.person, color: SocialTheme.blue, size: radius * 1.15) : null,
      ),
      if (online)
        Positioned(right: 0, bottom: 0, child: Container(
          width: radius * .48, height: radius * .48,
          decoration: BoxDecoration(color: const Color(0xFF20B15A), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
        )),
    ]);
  }
}

/// Header kecil untuk post feed maupun diskusi grup.
class SocialPostHeader extends StatelessWidget {
  final String avatar;
  final String name;
  final String time;
  final VoidCallback? onMore;

  const SocialPostHeader({super.key, required this.avatar, required this.name, required this.time, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SocialAvatar(imageUrl: avatar, radius: 22),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: SocialTheme.text)),
        const SizedBox(height: 2),
        Row(children: [Text(time, style: GoogleFonts.inter(fontSize: 10, color: SocialTheme.muted)), const SizedBox(width: 4), const Icon(Icons.public, size: 11, color: SocialTheme.muted)]),
      ])),
      IconButton(onPressed: onMore ?? () {}, icon: const Icon(Icons.more_horiz), tooltip: 'Opsi postingan'),
    ]);
  }
}

/// Grid foto fleksibel untuk 1 sampai 4 foto.
class SocialImageGrid extends StatelessWidget {
  final List<String> images;
  const SocialImageGrid({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    final visible = images.take(4).toList();
    if (visible.length == 1) return _image(visible.first, height: 250);
    return SizedBox(height: 250, child: GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 3, mainAxisSpacing: 3),
      itemBuilder: (_, index) => _image(visible[index]),
    ));
  }

  Widget _image(String url, {double? height}) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Container(height: height, color: const Color(0xFFE9EEF5), child: Image.network(
      url, width: double.infinity, height: double.infinity, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_outlined, size: 38, color: SocialTheme.muted)),
    )),
  );
}

/// Tombol Rekber khusus posting produk.
class RekberButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  const RekberButton({super.key, this.onPressed, this.label = 'Beli lewat Rekber'});

  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity, child: FilledButton.icon(
    onPressed: onPressed ?? () {}, icon: const Icon(Icons.shield_outlined, size: 18),
    label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12)),
    style: FilledButton.styleFrom(backgroundColor: SocialTheme.blue, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
  ));
}

/// Footer Like / Komentar / Bagikan yang dipakai ulang.
class SocialInteractionBar extends StatelessWidget {
  final int likes;
  final int comments;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  const SocialInteractionBar({super.key, required this.likes, required this.comments, this.onLike, this.onComment, this.onShare});

  @override
  Widget build(BuildContext context) => Column(children: [
    const Divider(height: 18, color: SocialTheme.border),
    Row(children: [
      _action(Icons.thumb_up_outlined, 'Suka', '$likes', onLike),
      _action(Icons.mode_comment_outlined, 'Komentar', '$comments', onComment),
      _action(Icons.share_outlined, 'Bagikan', '', onShare),
    ]),
  ]);

  Widget _action(IconData icon, String label, String count, VoidCallback? onTap) => Expanded(child: InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(10),
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 19, color: SocialTheme.muted), const SizedBox(width: 5),
      Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: SocialTheme.muted)),
      if (count.isNotEmpty) ...[const SizedBox(width: 4), Text(count, style: GoogleFonts.inter(fontSize: 10, color: SocialTheme.muted))],
    ])),
  ));
}

/// Card putih standar untuk modul sosial.
class SocialCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const SocialCard({super.key, required this.child, this.padding = const EdgeInsets.all(14)});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: SocialTheme.border)),
    padding: padding, child: child,
  );
}

/// Tab reusable untuk Profil dan Grup.
class SocialTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const SocialTab({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(child: InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: selected ? SocialTheme.blue : Colors.transparent, width: 2.5))),
      child: Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: selected ? SocialTheme.blue : SocialTheme.muted)),
    ),
  ));
}
