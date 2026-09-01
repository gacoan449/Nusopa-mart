import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/social_service.dart';

/// Chat antar pengguna. Berbeda dari Chat Admin lama.
class DirectChatScreen extends StatefulWidget {
  final String otherUid;
  final String title;
  const DirectChatScreen({super.key, required this.otherUid, required this.title});
  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final text = TextEditingController();
  XFile? image;
  bool sending = false;
  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get conversationId => SocialService.instance.conversationId(widget.otherUid);
  CollectionReference<Map<String, dynamic>> get messages => FirebaseFirestore.instance.collection('direct_chats').doc(conversationId).collection('messages');

  Future<void> pick() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1600);
    if (file != null && mounted) setState(() => image = file);
  }

  Future<void> send() async {
    if (uid.isEmpty || sending || (text.text.trim().isEmpty && image == null)) return;
    setState(() => sending = true);
    try {
      var url = '';
      if (image != null) {
        final ref = FirebaseStorage.instance.ref('direct_chats/$conversationId/${DateTime.now().microsecondsSinceEpoch}.jpg');
        await ref.putFile(File(image!.path), SettableMetadata(contentType: 'image/jpeg'));
        url = await ref.getDownloadURL();
      }
      final body = text.text.trim();
      await FirebaseFirestore.instance.collection('direct_chats').doc(conversationId).set({
        'participants': [uid, widget.otherUid],
        'lastMessage': body.isEmpty ? '📷 Foto' : body,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await messages.add({'senderId': uid, 'receiverId': widget.otherUid, 'text': body, 'imageUrl': url, 'createdAt': FieldValue.serverTimestamp()});
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': widget.otherUid, 'actorId': uid, 'actorName': FirebaseAuth.instance.currentUser?.email ?? 'Pengguna',
        'type': 'message', 'referenceId': conversationId,
        'message': body.isEmpty ? 'mengirim foto kepada Anda.' : 'mengirim pesan kepada Anda.',
        'read': false, 'createdAt': FieldValue.serverTimestamp(),
      });
      text.clear();
      if (mounted) setState(() => image = null);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesan gagal dikirim: $e')));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(children: [
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: messages.orderBy('createdAt').snapshots(),
          builder: (_, snap) {
            final docs = snap.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            if (docs.isEmpty) return const Center(child: Text('Belum ada pesan.'));
            return ListView.builder(
              padding: const EdgeInsets.all(12), itemCount: docs.length,
              itemBuilder: (_, i) {
                final d = docs[i].data();
                final mine = d['senderId'] == uid;
                final url = (d['imageUrl'] ?? '').toString();
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(9),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
                    decoration: BoxDecoration(color: mine ? const Color(0xFF126BFF) : Colors.white, borderRadius: BorderRadius.circular(15)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (url.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.network(url, width: 220, height: 180, fit: BoxFit.cover)),
                      if ((d['text'] ?? '').toString().isNotEmpty) Padding(padding: EdgeInsets.only(top: url.isEmpty ? 0 : 7), child: Text(d['text'].toString(), style: TextStyle(color: mine ? Colors.white : Colors.black87))),
                    ]),
                  ),
                );
              },
            );
          },
        )),
        if (image != null) Container(color: Colors.white, padding: const EdgeInsets.all(6), child: Row(children: [
          Image.file(File(image!.path), width: 55, height: 55, fit: BoxFit.cover),
          const Expanded(child: Text('Foto siap dikirim')),
          IconButton(onPressed: () => setState(() => image = null), icon: const Icon(Icons.close)),
        ])),
        SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(6, 5, 6, 6), child: Row(children: [
          IconButton(onPressed: sending ? null : pick, icon: const Icon(Icons.photo_outlined, color: Color(0xFF126BFF))),
          Expanded(child: TextField(controller: text, minLines: 1, maxLines: 4, decoration: InputDecoration(hintText: 'Tulis pesan...', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none)))),
          IconButton(onPressed: sending ? null : send, icon: const Icon(Icons.send_rounded, color: Color(0xFF126BFF))),
        ]))),
      ]),
    );
  }

  @override
  void dispose() { text.dispose(); super.dispose(); }
}
