import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/social_service.dart';
import '../widgets/social_widgets.dart';

/// Feed sosial utama. Tidak ada post dummy: data hanya berasal dari Firestore.
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
        IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SocialNotificationsScreen())), icon: const Icon(Icons.notifications_none_rounded)),
        IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DirectChatsScreen())), icon: const Icon(Icons.chat_bubble_outline_rounded)),
      ],
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: SocialService.instance.feed(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Feed tidak dapat dimuat.\n${snapshot.error}', textAlign: TextAlign.center));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final posts = snapshot.data?.docs ?? const [];
        return ListView(padding: const EdgeInsets.all(10), children: [
          _searchBar(), const SizedBox(height: 10), _createPost(context), const SizedBox(height: 10),
          if (posts.isEmpty) _empty() else ...posts.map((doc) => Padding(padding: const EdgeInsets.only(bottom: 10), child: SocialPostCard(postId: doc.id, data: doc.data()))),
        ]);
      },
    ),
  );

  Widget _searchBar() => SocialCard(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11), child: Row(children: [const Icon(Icons.search, color: SocialTheme.muted), const SizedBox(width: 8), Expanded(child: Text('Cari orang, postingan, produk, atau grup...', style: GoogleFonts.inter(color: SocialTheme.muted, fontSize: 12)))]));

  Widget _createPost(BuildContext context) => SocialCard(child: Column(children: [
    Row(children: [const SocialAvatar(imageUrl: '', radius: 21), const SizedBox(width: 10), Expanded(child: InkWell(onTap: () => _compose(context), borderRadius: BorderRadius.circular(24), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: SocialTheme.background, borderRadius: BorderRadius.circular(24)), child: Text('Apa yang Anda pikirkan atau ingin Anda cari?', style: GoogleFonts.inter(color: SocialTheme.muted, fontSize: 12)))))]),
    const Divider(height: 22),
    Row(children: [Expanded(child: TextButton.icon(onPressed: () => _compose(context, choosePhoto: true), icon: const Icon(Icons.photo_library_outlined, color: SocialTheme.blue), label: const Text('Foto'))), Expanded(child: TextButton.icon(onPressed: () => _compose(context), icon: const Icon(Icons.sell_outlined, color: SocialTheme.blue), label: const Text('Tag Produk')))]),
  ]));

  Widget _empty() => SocialCard(child: Column(children: [const Icon(Icons.dynamic_feed_outlined, size: 46, color: SocialTheme.muted), const SizedBox(height: 8), Text('Belum ada postingan', style: GoogleFonts.inter(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text('Postingan pengguna akan muncul di sini.', style: GoogleFonts.inter(fontSize: 12, color: SocialTheme.muted))]));

  Future<void> _compose(BuildContext context, {bool choosePhoto = false}) async {
    final controller = TextEditingController();
    final images = <XFile>[];
    if (choosePhoto) images.addAll(await ImagePicker().pickMultiImage(imageQuality: 82, maxWidth: 1600));
    if (!context.mounted) { controller.dispose(); return; }
    await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, builder: (_) => _Composer(controller: controller, images: images));
    controller.dispose();
  }
}

class _Composer extends StatefulWidget {
  final TextEditingController controller; final List<XFile> images;
  const _Composer({required this.controller, required this.images});
  @override State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  bool saving = false;
  Future<void> pick() async { final files = await ImagePicker().pickMultiImage(imageQuality: 82, maxWidth: 1600); if (mounted) setState(() => widget.images.addAll(files.take(4 - widget.images.length))); }
  Future<void> publish() async {
    if (saving || (widget.controller.text.trim().isEmpty && widget.images.isEmpty)) return;
    setState(() => saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final urls = <String>[];
      for (final file in widget.images) { final ref = FirebaseStorage.instance.ref('posts/$uid/${DateTime.now().microsecondsSinceEpoch}.jpg'); await ref.putFile(File(file.path), SettableMetadata(contentType: 'image/jpeg')); urls.add(await ref.getDownloadURL()); }
      await SocialService.instance.createPost(text: widget.controller.text, imageUrls: urls);
      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat postingan: $e'))); }
    finally { if (mounted) setState(() => saving = false); }
  }
  @override Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16), child: Column(mainAxisSize: MainAxisSize.min, children: [Row(children: [Text('Buat postingan', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18)), const Spacer(), IconButton(onPressed: saving ? null : () => Navigator.pop(context), icon: const Icon(Icons.close))]), TextField(controller: widget.controller, maxLines: 5, autofocus: widget.images.isEmpty, decoration: const InputDecoration(hintText: 'Apa yang Anda pikirkan atau ingin Anda cari?', border: InputBorder.none)), if (widget.images.isNotEmpty) SizedBox(height: 82, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: widget.images.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) => Stack(children: [Image.file(File(widget.images[i].path), width: 82, height: 82, fit: BoxFit.cover), Positioned(right: 0, child: GestureDetector(onTap: saving ? null : () => setState(() => widget.images.removeAt(i)), child: const Icon(Icons.cancel)))]))), Row(children: [TextButton.icon(onPressed: saving || widget.images.length >= 4 ? null : pick, icon: const Icon(Icons.photo_library_outlined), label: const Text('Foto')), const Spacer(), FilledButton.icon(onPressed: saving ? null : publish, icon: const Icon(Icons.send_rounded), label: Text(saving ? 'Mengirim...' : 'Posting'))])]));
}

class SocialPostCard extends StatelessWidget {
  final String postId; final Map<String, dynamic> data;
  const SocialPostCard({super.key, required this.postId, required this.data});
  @override Widget build(BuildContext context) {
    final authorId = (data['authorId'] ?? '').toString();
    final images = ((data['imageUrls'] as List?) ?? const []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    final created = data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate() : null;
    final likes = (data['likeCount'] as num?)?.toInt() ?? 0;
    final comments = (data['commentCount'] as num?)?.toInt() ?? 0;
    return SocialCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SocialPostHeader(avatar: (data['authorPhotoUrl'] ?? '').toString(), name: (data['authorName'] ?? 'Pengguna').toString(), time: _time(created), onMore: () => _more(context, authorId)),
      if ((data['text'] ?? '').toString().trim().isNotEmpty) ...[const SizedBox(height: 4), Text(data['text'].toString(), style: GoogleFonts.inter(fontSize: 13, height: 1.45))],
      if (images.isNotEmpty) ...[const SizedBox(height: 12), SocialImageGrid(images: images)],
      if ((data['productId'] ?? '').toString().isNotEmpty) ...[const SizedBox(height: 10), RekberButton(onPressed: () {})],
      SocialInteractionBar(likes: likes, comments: comments, onLike: () => SocialService.instance.toggleLike(postId, authorId: authorId), onComment: () => _comments(context, authorId), onShare: () => _share(context, authorId)),
    ]));
  }
  Future<void> _comments(BuildContext context, String authorId) async { final c = TextEditingController(); await showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => _Comments(postId: postId, authorId: authorId, controller: c)); c.dispose(); }
  Future<void> _share(BuildContext context, String authorId) async { await SocialService.instance.sharePost(postId, authorId: authorId); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Postingan dibagikan.'))); }
  void _more(BuildContext context, String authorId) { final mine = FirebaseAuth.instance.currentUser?.uid == authorId; showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [if (mine) ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Hapus postingan'), onTap: () async { Navigator.pop(context); await FirebaseFirestore.instance.collection('posts').doc(postId).delete(); }) else ListTile(leading: const Icon(Icons.flag_outlined), title: const Text('Laporkan postingan'), onTap: () => Navigator.pop(context))]))); }
  String _time(DateTime? t) { if (t == null) return 'baru saja'; final d = DateTime.now().difference(t); if (d.inMinutes < 1) return 'baru saja'; if (d.inHours < 1) return '${d.inMinutes} m'; if (d.inDays < 1) return '${d.inHours} j'; return '${d.inDays} h'; }
}

class _Comments extends StatelessWidget {
  final String postId, authorId; final TextEditingController controller;
  const _Comments({required this.postId, required this.authorId, required this.controller});
  @override Widget build(BuildContext context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: SizedBox(height: MediaQuery.of(context).size.height * .65, child: Column(children: [Padding(padding: const EdgeInsets.all(14), child: Text('Komentar', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18))), Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: SocialService.instance.comments(postId), builder: (_, snap) { final docs = snap.data?.docs ?? const []; if (docs.isEmpty) return const Center(child: Text('Belum ada komentar.')); return ListView.builder(itemCount: docs.length, itemBuilder: (_, i) { final d = docs[i].data(); return ListTile(leading: SocialAvatar(imageUrl: (d['authorPhotoUrl'] ?? '').toString(), radius: 18), title: Text((d['authorName'] ?? 'Pengguna').toString(), style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text((d['text'] ?? '').toString())); }); })), Padding(padding: const EdgeInsets.all(10), child: Row(children: [Expanded(child: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Tulis komentar...', filled: true))), IconButton(onPressed: () async { await SocialService.instance.addComment(postId, authorId: authorId, text: controller.text); controller.clear(); }, icon: const Icon(Icons.send_rounded, color: SocialTheme.blue))]))])));
}

class SocialNotificationsScreen extends StatelessWidget {
  const SocialNotificationsScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Notifikasi')), body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: SocialService.instance.notifications(), builder: (_, snap) { if (snap.hasError) return Center(child: Text('Notifikasi tidak dapat dimuat: ${snap.error}')); final docs = snap.data?.docs ?? const []; if (docs.isEmpty) return const Center(child: Text('Belum ada notifikasi.')); return ListView.builder(itemCount: docs.length, itemBuilder: (_, i) { final d = docs[i]; final x = d.data(); return ListTile(leading: const Icon(Icons.notifications_none_rounded), title: Text((x['actorName'] ?? 'Pengguna').toString()), subtitle: Text((x['message'] ?? '').toString()), trailing: (x['read'] ?? false) ? null : const CircleAvatar(radius: 5), onTap: () => SocialService.instance.markNotificationRead(d.id)); }); }));
}

/// Placeholder yang bersih sampai daftar percakapan user benar-benar tersedia di Firestore.
class DirectChatsScreen extends StatelessWidget {
  const DirectChatsScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Pesan')), body: const Center(child: Text('Belum ada percakapan. Buka profil pengguna untuk memulai chat.')));
}
