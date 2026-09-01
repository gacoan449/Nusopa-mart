import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'direct_chat_screen.dart';
import 'social_profile_screen.dart';
import 'groups_screen.dart';

/// Pencarian sosial lintas pengguna, produk, dan grup.
class SocialSearchScreen extends StatefulWidget {
  final String initialQuery;
  const SocialSearchScreen({super.key, this.initialQuery = ''});
  @override State<SocialSearchScreen> createState() => _SocialSearchScreenState();
}

class _SocialSearchScreenState extends State<SocialSearchScreen> {
  late final TextEditingController controller;
  String query = '';

  @override void initState() { super.initState(); controller = TextEditingController(text: widget.initialQuery); query = widget.initialQuery.trim(); }
  void submit(String value) => setState(() => query = value.trim());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: TextField(controller: controller, autofocus: widget.initialQuery.isEmpty, textInputAction: TextInputAction.search, onSubmitted: submit, decoration: const InputDecoration(hintText: 'Cari orang, produk, grup...', border: InputBorder.none))),
    body: query.isEmpty ? const Center(child: Text('Cari pengguna, produk, atau grup.')) : ListView(padding: const EdgeInsets.all(12), children: [
      _section('Orang', FirebaseFirestore.instance.collection('social_profiles').orderBy('displayName').startAt([query]).endAt(['$query\uf8ff']).limit(20).snapshots(), (d) => ListTile(leading: CircleAvatar(backgroundImage: (d['photoUrl'] ?? '').toString().isNotEmpty ? NetworkImage(d['photoUrl']) : null, child: (d['photoUrl'] ?? '').toString().isEmpty ? const Icon(Icons.person) : null), title: Text((d['displayName'] ?? 'Pengguna').toString()), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SocialProfileScreen(userId: d['uid']?.toString(), userName: d['displayName']?.toString()))))),
      _section('Produk', FirebaseFirestore.instance.collection('products').orderBy('name').startAt([query]).endAt(['$query\uf8ff']).limit(20).snapshots(), (d) => ListTile(leading: const Icon(Icons.shopping_bag_outlined), title: Text((d['name'] ?? 'Produk').toString()), subtitle: Text('Rp${d['price'] ?? 0}'))),
      _section('Grup', FirebaseFirestore.instance.collection('groups').orderBy('name').startAt([query]).endAt(['$query\uf8ff']).limit(20).snapshots(), (d) => ListTile(leading: const Icon(Icons.groups_outlined), title: Text((d['name'] ?? 'Grup').toString()), subtitle: Text((d['privacy'] ?? 'Publik').toString()), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsScreen())))),
    ]),
  );

  Widget _section(String title, Stream<QuerySnapshot<Map<String, dynamic>>> stream, Widget Function(Map<String, dynamic>) tile) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: stream, builder: (_, snap) { final docs = snap.data?.docs ?? const []; return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))), if (docs.isEmpty) const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Tidak ditemukan.')) else ...docs.map((d) => tile({...d.data(), 'uid': d.id}))]); });

  @override void dispose() { controller.dispose(); super.dispose(); }
}
