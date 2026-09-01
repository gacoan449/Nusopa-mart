import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/social_widgets.dart';

/// Jelajah Grup + detail komunitas dalam satu modul.
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final groups = const [
    {'name': 'Komunitas Gadget Bekas', 'members': '12,4 rb', 'privacy': 'Publik', 'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=900'},
    {'name': 'Hobi Tanaman & Kebun', 'members': '8,7 rb', 'privacy': 'Publik', 'image': 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=900'},
    {'name': 'Jual Beli Motor Indonesia', 'members': '21,1 rb', 'privacy': 'Privat', 'image': 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=900'},
    {'name': 'Kuliner Nusantara', 'members': '15,8 rb', 'privacy': 'Publik', 'image': 'https://images.unsplash.com/photo-1547592180-85f173990554?w=900'},
  ];
  Map<String, String>? selected;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SocialTheme.background,
    appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.white, title: Text(selected == null ? 'Grup & Komunitas' : selected!['name']!, style: GoogleFonts.inter(fontWeight: FontWeight.w800)), leading: selected == null ? null : IconButton(onPressed: () => setState(() => selected = null), icon: const Icon(Icons.arrow_back))),
    body: selected == null ? _discovery() : _detail(selected!),
  );

  Widget _discovery() => ListView(padding: const EdgeInsets.all(12), children: [
    SocialCard(child: Row(children: [const Icon(Icons.search, color: SocialTheme.muted), const SizedBox(width: 8), Expanded(child: Text('Cari grup atau komunitas...', style: GoogleFonts.inter(color: SocialTheme.muted, fontSize: 12)))])),
    const SizedBox(height: 14),
    Text('Jelajah Grup', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900)),
    const SizedBox(height: 10),
    GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: groups.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .78),
      itemBuilder: (_, i) => _groupCard(groups[i]),
    ),
  ]);

  Widget _groupCard(Map<String, String> group) => SocialCard(padding: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.network(group['image']!, height: 115, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 115, child: Icon(Icons.groups, size: 40)))),
    Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(group['name']!, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12)),
      const SizedBox(height: 5), Text('${group['members']} anggota • ${group['privacy']}', style: GoogleFonts.inter(fontSize: 9, color: SocialTheme.muted)),
      const SizedBox(height: 9), SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => setState(() => selected = group), child: const Text('Gabung'))),
    ])),
  ]));

  Widget _detail(Map<String, String> group) => ListView(children: [
    Stack(children: [
      Image.network(group['image']!, height: 190, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 190)),
      Positioned(left: 16, bottom: 14, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)), child: Text(group['privacy']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))),
    ]),
    Padding(padding: const EdgeInsets.fromLTRB(14, 14, 14, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(group['name']!, style: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5), Text('${group['members']} anggota', style: GoogleFonts.inter(color: SocialTheme.muted, fontSize: 12)),
      const SizedBox(height: 10), FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.group_add_outlined), label: const Text('Gabung Grup')),
    ])),
    const SizedBox(height: 8),
    const Divider(height: 1),
    Row(children: [SocialTab(label: 'Diskusi', selected: true, onTap: () {}), SocialTab(label: 'Anggota', selected: false, onTap: () {})]),
    Padding(padding: const EdgeInsets.all(12), child: Column(children: [
      SocialCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [SocialAvatar(imageUrl: '', radius: 19), SizedBox(width: 9), Text('Anggota komunitas', style: TextStyle(fontWeight: FontWeight.w800))]), const SizedBox(height: 10), Text('Ada yang punya rekomendasi barang bagus minggu ini?', style: TextStyle(height: 1.4)), SocialInteractionBar(likes: 18, comments: 4, onLike: () {}, onComment: () {}, onShare: () {})])),
      const SizedBox(height: 10),
      SocialCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SocialPostHeader(avatar: '', name: 'Admin Grup', time: '2 jam'), Text('Silakan berdiskusi dan jual beli sesuai aturan grup. Untuk transaksi, gunakan Rekber Nusopa.Mart.', style: GoogleFonts.inter(fontSize: 13, height: 1.45)), const SizedBox(height: 10), RekberButton(onPressed: () {}), SocialInteractionBar(likes: 35, comments: 7, onLike: () {}, onComment: () {}, onShare: () {})])),
    ])),
  ]);
}
