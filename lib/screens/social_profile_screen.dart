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
  int tab = 0; bool? following;
  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get profileUid => widget.userId ?? uid;
  bool get own => profileUid == uid;

  @override void initState() { super.initState(); _refreshFollow(); }
  Future<void> _refreshFollow() async { if (!own && profileUid.isNotEmpty) { final v = await SocialService.instance.isFollowing(profileUid); if (mounted) setState(() => following = v); } }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: SocialTheme.background,
    appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.white, title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('social_profiles').doc(profileUid).snapshots(), builder: (_, s) => Text((s.data?.data()?['displayName'] ?? widget.userName ?? 'Profil').toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w800))), actions: [IconButton(onPressed: () => _menu(context), icon: const Icon(Icons.more_horiz))]),
    body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('social_profiles').doc(profileUid).snapshots(), builder: (context, snap) { final p = snap.data?.data() ?? {}; final name = (p['displayName'] ?? widget.userName ?? 'Pengguna').toString(); return CustomScrollView(slivers: [SliverToBoxAdapter(child: _header(p, name)), SliverToBoxAdapter(child: Container(color: Colors.white, child: Row(children: [SocialTab(label: 'Postingan Sosial', selected: tab == 0, onTap: () => setState(() => tab = 0)), SocialTab(label: 'Produk Jualan', selected: tab == 1, onTap: () => setState(() => tab = 1))]))), SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(12), child: tab == 0 ? _posts() : _products()))]); }),
  );

  Widget _header(Map<String, dynamic> p, String name) {
    final cover = (p['coverPhotoUrl'] ?? '').toString(), photo = (p['photoUrl'] ?? '').toString(), bio = (p['bio'] ?? '').toString();
    final rating = (p['rekberRating'] as num?)?.toDouble() ?? 0;
    return Container(color: Colors.white, child: Column(children: [Stack(clipBehavior: Clip.none, children: [SizedBox(height: 190, width: double.infinity, child: cover.isEmpty ? Container(color: const Color(0xFFE7EEF9)) : Image.network(cover, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE7EEF9)))), Positioned(left: 18, bottom: -48, child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: SocialAvatar(imageUrl: photo, radius: 48)))]), Padding(padding: const EdgeInsets.fromLTRB(18, 58, 18, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w900)), if (bio.isNotEmpty) ...[const SizedBox(height: 5), Text(bio, style: GoogleFonts.inter(fontSize: 11, color: SocialTheme.muted, height: 1.4))], const SizedBox(height: 14), Row(children: [_count('followers', 'Pengikut'), _count('following', 'Mengikuti'), Expanded(child: Column(children: [Text(rating > 0 ? rating.toStringAsFixed(1) : '—', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900)), Text('Rating Rekber', style: GoogleFonts.inter(fontSize: 9, color: SocialTheme.muted))]))]), const SizedBox(height: 12), own ? Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.edit_outlined), label: const Text('Edit Profil'))), const SizedBox(width: 8), Expanded(child: FilledButton.icon(onPressed: () => _menu(context), icon: const Icon(Icons.shield_outlined), label: const Text('Rekber')))]) : Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () async { await SocialService.instance.toggleFollow(profileUid); await _refreshFollow(); }, icon: Icon(following == true ? Icons.check : Icons.person_add_alt_1), label: Text(following == true ? 'Mengikuti' : 'Ikuti'))), const SizedBox(width: 8), Expanded(child: FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DirectChatScreen(otherUid: profileUid, title: name))), icon: const Icon(Icons.chat_bubble_outline), label: const Text('Kirim Pesan')))])]))]));
  }

  Widget _count(String collection, String label) => Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('social_profiles').doc(profileUid).collection(collection).snapshots(), builder: (_, s) => Column(children: [Text('${s.data?.docs.length ?? 0}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900)), Text(label, style: GoogleFonts.inter(fontSize: 9, color: SocialTheme.muted))])));

  Widget _posts() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('posts').where('authorId', isEqualTo: profileUid).snapshots(), builder: (_, snap) { final docs = [...(snap.data?.docs ?? const [])]; docs.sort((a, b) => ((b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0).compareTo((a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0)); if (docs.isEmpty) return _empty('Belum ada postingan.'); return Column(children: docs.map((d) => Padding(padding: const EdgeInsets.only(bottom: 10), child: SocialPostCard(postId: d.id, data: d.data())).toList()); });

  Widget _products() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('products').where('sellerId', isEqualTo: profileUid).snapshots(), builder: (_, snap) { final docs = snap.data?.docs ?? const []; if (docs.isEmpty) return _empty('Belum ada produk jualan aktif.'); return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: docs.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .68), itemBuilder: (context, i) { final d = docs[i].data(), url = (d['imageUrl'] ?? '').toString(); return SocialCard(padding: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: url.isEmpty ? const Center(child: Icon(Icons.image_outlined, size: 42)) : Image.network(url, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined))))), Padding(padding: const EdgeInsets.all(9), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text((d['name'] ?? 'Produk').toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 4), Text('Rp${d['price'] ?? 0}', style: GoogleFonts.inter(color: SocialTheme.blue, fontWeight: FontWeight.w900)), const SizedBox(height: 6), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen())), icon: const Icon(Icons.shield_outlined, size: 15), label: const Text('Belanja / Rekber')))]))])); }); });

  Widget _empty(String text) => SocialCard(child: Padding(padding: const EdgeInsets.all(20), child: Center(child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.inter(color: SocialTheme.muted))));

  void _menu(BuildContext context) => showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: own ? [ListTile(leading: const Icon(Icons.storefront_outlined), title: const Text('Belanja & Marketplace'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()))), ListTile(leading: const Icon(Icons.receipt_long_outlined), title: const Text('Pesanan Saya'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()))), ListTile(leading: const Icon(Icons.store_outlined), title: const Text('Kelola Produk & Toko'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerDashboard()))), ListTile(leading: const Icon(Icons.shield_outlined), title: const Text('Rekber & Perlindungan Transaksi'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RekberInfoScreen()))), ListTile(leading: const Icon(Icons.headset_mic_outlined), title: const Text('Chat Admin'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())))] : [ListTile(leading: const Icon(Icons.flag_outlined), title: const Text('Laporkan profil'), onTap: () => Navigator.pop(context)), ListTile(leading: const Icon(Icons.block_outlined), title: const Text('Blokir pengguna'), onTap: () => Navigator.pop(context))])));
}
