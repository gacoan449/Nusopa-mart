import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/social_service.dart';
import '../widgets/social_widgets.dart';
import 'chat_screen.dart';
import 'direct_chat_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'rekber_info_screen.dart';
import 'seller_dashboard.dart';

/// Profil sosial nyata. Tidak menampilkan angka, postingan, produk, atau foto dummy.
class SocialProfileScreen extends StatefulWidget {
  final String? userId;
  final String? userName;
  const SocialProfileScreen({super.key, this.userId, this.userName});
  @override State<SocialProfileScreen> createState() => _SocialProfileScreenState();
}

class _SocialProfileScreenState extends State<SocialProfileScreen> {
  int tab = 0;
  bool? following;
  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get profileUid => widget.userId ?? uid;
  bool get own => profileUid == uid;

  @override
  void initState() {
    super.initState();
    _refreshFollow();
  }

  Future<void> _refreshFollow() async {
    if (!own && profileUid.isNotEmpty) {
      final value = await SocialService.instance.isFollowing(profileUid);
      if (mounted) setState(() => following = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SocialTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('social_profiles').doc(profileUid).snapshots(),
          builder: (_, snapshot) {
            final data = snapshot.data?.data();
            final title = (data?['displayName'] ?? widget.userName ?? 'Profil').toString();
            return Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800));
          },
        ),
        actions: [IconButton(onPressed: () => _menu(context), icon: const Icon(Icons.more_horiz))],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('social_profiles').doc(profileUid).snapshots(),
        builder: (context, snapshot) {
          final profile = snapshot.data?.data() ?? <String, dynamic>{};
          final name = (profile['displayName'] ?? widget.userName ?? 'Pengguna').toString();
          return CustomScrollView(slivers: [
            SliverToBoxAdapter(child: _header(profile, name)),
            SliverToBoxAdapter(child: Container(color: Colors.white, child: Row(children: [
              SocialTab(label: 'Postingan Sosial', selected: tab == 0, onTap: () => setState(() => tab = 0)),
              SocialTab(label: 'Produk Jualan', selected: tab == 1, onTap: () => setState(() => tab = 1)),
            ]))),
            if (tab == 0) _posts() else _products(),
          ]);
        },
      ),
    );
  }

  Widget _header(Map<String, dynamic> profile, String name) {
    final cover = (profile['coverPhotoUrl'] ?? '').toString();
    final photo = (profile['photoUrl'] ?? '').toString();
    final bio = (profile['bio'] ?? '').toString();
    final rating = (profile['rekberRating'] as num?)?.toDouble() ?? 0;
    return Container(color: Colors.white, child: Column(children: [
      Stack(clipBehavior: Clip.none, children: [
        SizedBox(height: 190, width: double.infinity, child: cover.isEmpty ? Container(color: const Color(0xFFE7EEF9)) : Image.network(cover, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE7EEF9)))),
        Positioned(left: 18, bottom: -48, child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: SocialAvatar(imageUrl: photo, radius: 48))),
      ]),
      Padding(padding: const EdgeInsets.fromLTRB(18, 58, 18, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w900)),
        if (bio.isNotEmpty) ...[const SizedBox(height: 5), Text(bio, style: GoogleFonts.inter(fontSize: 11, color: SocialTheme.muted, height: 1.4))],
        const SizedBox(height: 14),
        Row(children: [_count('followers', 'Pengikut'), _count('following', 'Mengikuti'), Expanded(child: Column(children: [Text(rating > 0 ? rating.toStringAsFixed(1) : '—', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900)), Text('Rating Rekber', style: GoogleFonts.inter(fontSize: 9, color: SocialTheme.muted))]))]),
        const SizedBox(height: 12),
        own ? Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.edit_outlined), label: const Text('Edit Profil'))), const SizedBox(width: 8), Expanded(child: FilledButton.icon(onPressed: () => _menu(context), icon: const Icon(Icons.shield_outlined), label: const Text('Rekber')))]) : Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () async { await SocialService.instance.toggleFollow(profileUid); await _refreshFollow(); }, icon: Icon(following == true ? Icons.check : Icons.person_add_alt_1), label: Text(following == true ? 'Mengikuti' : 'Ikuti'))), const SizedBox(width: 8), Expanded(child: FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DirectChatScreen(otherUid: profileUid, title: name))), icon: const Icon(Icons.chat_bubble_outline), label: const Text('Kirim Pesan')))]),
      ]),
    ]));
  }

  Widget _count(String collection, String label) => Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('social_profiles').doc(profileUid).collection(collection).snapshots(), builder: (_, snapshot) => Column(children: [Text('${snapshot.data?.docs.length ?? 0}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900)), Text(label, style: GoogleFonts.inter(fontSize: 9, color: SocialTheme.muted))])));

  Widget _postCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final images = (data['imageUrls'] as List?)?.map((e) => e.toString()).where((e) => e.isNotEmpty).toList() ?? <String>[];
    final created = data['createdAt'] as Timestamp?;
    final time = created == null ? 'Baru' : _time(created.toDate());
    return SocialCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SocialPostHeader(avatar: (data['authorPhotoUrl'] ?? '').toString(), name: (data['authorName'] ?? 'Pengguna').toString(), time: time),
      if ((data['text'] ?? '').toString().trim().isNotEmpty) ...[const SizedBox(height: 5), Text(data['text'].toString(), style: GoogleFonts.inter(fontSize: 13, height: 1.45))],
      if (images.isNotEmpty) ...[const SizedBox(height: 10), SocialImageGrid(images: images)],
      SocialInteractionBar(likes: (data['likeCount'] as num?)?.toInt() ?? 0, comments: (data['commentCount'] as num?)?.toInt() ?? 0, onLike: () => SocialService.instance.toggleLike(doc.id, authorId: (data['authorId'] ?? '').toString()), onComment: () {}, onShare: () => SocialService.instance.sharePost(doc.id, authorId: (data['authorId'] ?? '').toString())),
    ]));
  }

  String _time(DateTime date) {
    final minutes = DateTime.now().difference(date).inMinutes;
    if (minutes < 1) return 'Baru saja';
    if (minutes < 60) return '$minutes mnt';
    final hours = minutes ~/ 60;
    if (hours < 24) return '$hours jam';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _empty(String text) => SliverToBoxAdapter(child: SocialCard(child: Padding(padding: const EdgeInsets.all(20), child: Center(child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.inter(color: SocialTheme.muted))))));

  Widget _posts() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection('posts').where('authorId', isEqualTo: profileUid).snapshots(),
    builder: (_, snapshot) {
      final docs = [...(snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>)];
      docs.sort((a, b) => ((b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0).compareTo((a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0));
      if (docs.isEmpty) return _empty('Belum ada postingan.');
      return SliverList(delegate: SliverChildBuilderDelegate((context, index) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _postCard(docs[index])), childCount: docs.length));
    },
  );

  Widget _products() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection('products').where('sellerId', isEqualTo: profileUid).snapshots(),
    builder: (_, snapshot) {
      final docs = snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      if (docs.isEmpty) return _empty('Belum ada produk jualan aktif.');
      return SliverToBoxAdapter(child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: docs.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .68),
        itemBuilder: (context, i) {
          final data = docs[i].data();
          final url = (data['imageUrl'] ?? '').toString();
          return SocialCard(padding: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: url.isEmpty ? const Center(child: Icon(Icons.image_outlined, size: 42)) : Image.network(url, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined))))),
            Padding(padding: const EdgeInsets.all(9), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text((data['name'] ?? 'Produk').toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 4), Text('Rp${data['price'] ?? 0}', style: GoogleFonts.inter(color: SocialTheme.blue, fontWeight: FontWeight.w900)), const SizedBox(height: 6), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen())), icon: const Icon(Icons.shield_outlined, size: 15), label: const Text('Belanja / Rekber')))])),
          ]));
        },
      ));
    },
  );

  void _menu(BuildContext context) {
    showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: own ? [
      ListTile(leading: const Icon(Icons.storefront_outlined), title: const Text('Belanja & Marketplace'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()))),
      ListTile(leading: const Icon(Icons.receipt_long_outlined), title: const Text('Pesanan Saya'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()))),
      ListTile(leading: const Icon(Icons.store_outlined), title: const Text('Kelola Produk & Toko'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerDashboard()))),
      ListTile(leading: const Icon(Icons.shield_outlined), title: const Text('Rekber & Perlindungan Transaksi'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RekberInfoScreen()))),
      ListTile(leading: const Icon(Icons.headset_mic_outlined), title: const Text('Chat Admin'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
    ] : [
      ListTile(leading: const Icon(Icons.flag_outlined), title: const Text('Laporkan profil'), onTap: () => Navigator.pop(context)),
      ListTile(leading: const Icon(Icons.block_outlined), title: const Text('Blokir pengguna'), onTap: () => Navigator.pop(context)),
    ])));
  }
}
