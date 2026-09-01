import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/group_service.dart';
import '../widgets/social_widgets.dart';
import 'create_group_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});
  @override State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  String? selectedId;
  Map<String, dynamic>? selected;
  String search = '';
  final searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SocialTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(selected == null ? 'Grup & Komunitas' : (selected!['name'] ?? 'Grup').toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        leading: selected == null ? null : IconButton(onPressed: () => setState(() { selected = null; selectedId = null; }), icon: const Icon(Icons.arrow_back)),
        actions: selected == null ? [IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen())), icon: const Icon(Icons.add_circle_outline))] : [],
      ),
      body: selected == null ? _discovery() : _detail(selectedId!, selected!),
    );
  }

  Widget _discovery() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: GroupService.instance.groups(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Grup tidak dapat dimuat.\n${snap.error}', textAlign: TextAlign.center));
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snap.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final filtered = docs.where((d) => search.isEmpty || (d.data()['name'] ?? '').toString().toLowerCase().contains(search.toLowerCase())).toList();
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            SocialCard(child: TextField(controller: searchController, onChanged: (v) => setState(() => search = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari grup atau komunitas...', border: InputBorder.none))),
            const SizedBox(height: 14),
            Row(children: [Text('Jelajah Grup', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900)), const Spacer(), TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen())), icon: const Icon(Icons.add), label: const Text('Buat'))]),
            const SizedBox(height: 10),
            if (filtered.isEmpty)
              SocialCard(child: Column(children: [const Icon(Icons.groups_outlined, size: 46, color: SocialTheme.muted), const SizedBox(height: 8), Text(search.isEmpty ? 'Belum ada grup.' : 'Grup tidak ditemukan.', style: GoogleFonts.inter(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text('Buat komunitas pertama Anda.', style: GoogleFonts.inter(fontSize: 11, color: SocialTheme.muted))]))
            else
              GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: filtered.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .72), itemBuilder: (_, i) => _groupCard(filtered[i])),
          ],
        );
      },
    );
  }

  Widget _groupCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final g = doc.data();
    final cover = (g['coverUrl'] ?? '').toString();
    return SocialCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: cover.isEmpty ? Container(color: const Color(0xFFE7EEF9), child: const Center(child: Icon(Icons.groups_outlined, size: 42))) : Image.network(cover, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE7EEF9), child: const Icon(Icons.broken_image_outlined))))),
        Padding(padding: const EdgeInsets.all(9), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text((g['name'] ?? 'Grup').toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 4),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: GroupService.instance.members(doc.id), builder: (_, m) => Text('${m.data?.docs.length ?? 0} anggota • ${(g['privacy'] ?? 'Publik').toString()}', style: GoogleFonts.inter(fontSize: 9, color: SocialTheme.muted))),
          const SizedBox(height: 7),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => setState(() { selectedId = doc.id; selected = g; }), child: const Text('Lihat Grup'))),
        ])),
      ]),
    );
  }

  Widget _detail(String groupId, Map<String, dynamic> group) {
    return ListView(children: [
      SizedBox(height: 180, width: double.infinity, child: (group['coverUrl'] ?? '').toString().isEmpty ? Container(color: const Color(0xFFE7EEF9), child: const Icon(Icons.groups_outlined, size: 60)) : Image.network(group['coverUrl'].toString(), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE7EEF9), child: const Icon(Icons.groups_outlined, size: 60)))),
      Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text((group['name'] ?? 'Grup').toString(), style: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: GroupService.instance.members(groupId), builder: (_, s) => Text('${s.data?.docs.length ?? 0} anggota • ${(group['privacy'] ?? 'Publik').toString()}', style: GoogleFonts.inter(fontSize: 12, color: SocialTheme.muted))),
        const SizedBox(height: 10),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('groups').doc(groupId).collection('members').doc(GroupService.instance.uid).snapshots(), builder: (_, s) { final member = s.data?.exists ?? false; return SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => GroupService.instance.join(groupId), icon: Icon(member ? Icons.check : Icons.group_add_outlined), label: Text(member ? 'Keluar Grup' : 'Gabung Grup'))); }),
      ])),
      const Divider(height: 1),
      Padding(padding: const EdgeInsets.all(12), child: Text('Diskusi', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: SocialTheme.blue))),
      _discussionComposer(groupId),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: GroupService.instance.discussions(groupId), builder: (_, snap) {
        final docs = snap.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Belum ada diskusi.')));
        return Column(children: docs.map((d) { final x = d.data(); return Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 10), child: SocialCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SocialPostHeader(avatar: (x['authorPhotoUrl'] ?? '').toString(), name: (x['authorName'] ?? 'Pengguna').toString(), time: ''), if ((x['text'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(x['text'].toString(), style: GoogleFonts.inter(fontSize: 13, height: 1.45))), SocialInteractionBar(likes: (x['likeCount'] as num?)?.toInt() ?? 0, comments: (x['commentCount'] as num?)?.toInt() ?? 0, onLike: () => GroupService.instance.likeDiscussion(groupId, d.id), onComment: () {}, onShare: () {})]))); }).toList());
      }),
    ]);
  }

  Widget _discussionComposer(String groupId) {
    final c = TextEditingController();
    return Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), child: SocialCard(child: Row(children: [Expanded(child: TextField(controller: c, minLines: 1, maxLines: 3, decoration: const InputDecoration(hintText: 'Tulis diskusi...', border: InputBorder.none))), IconButton(onPressed: () async { await GroupService.instance.createDiscussion(groupId, c.text); c.clear(); }, icon: const Icon(Icons.send_rounded, color: SocialTheme.blue))])));
  }

  @override
  void dispose() { searchController.dispose(); super.dispose(); }
}
