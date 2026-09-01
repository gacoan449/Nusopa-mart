import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _blue = Color(0xFF126BFF);

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text('Nusopa Control Center', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: _blue)),
        actions: [IconButton(onPressed: FirebaseAuth.instance.signOut, icon: const Icon(Icons.logout))],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, orderSnapshot) {
          final orders = orderSnapshot.data?.docs ?? const [];
          final paid = orders.where((d) => d.data()['status'] == 'MENUNGGU_VERIFIKASI').length;
          final dispute = orders.where((d) => d.data()['status'] == 'DISPUTE').length;
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('withdrawals').snapshots(),
            builder: (context, withdrawalSnapshot) {
              final withdrawals = withdrawalSnapshot.data?.docs.where((d) => d.data()['status'] == 'MENUNGGU_ADMIN').length ?? 0;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_blue, Color(0xFF67C5FF)]),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Admin online', style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      const Text('Kendali transaksi, chat, pembayaran dan sengketa.', style: TextStyle(color: Colors.white70)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _stat('Verifikasi', paid, Icons.receipt_long)),
                    const SizedBox(width: 10),
                    Expanded(child: _stat('Dispute', dispute, Icons.gavel_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _stat('Withdraw', withdrawals, Icons.account_balance_wallet_outlined)),
                  ]),
                  const SizedBox(height: 22),
                  _menu(context, Icons.chat_rounded, 'Inbox Chat', 'Balas chat pembeli dan penjual realtime', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminInboxScreen()))),
                  _menu(context, Icons.verified_rounded, 'Verifikasi Pembayaran', 'Order menunggu verifikasi', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOrdersScreen(filter: 'MENUNGGU_VERIFIKASI')))),
                  _menu(context, Icons.gavel_rounded, 'Sengketa', 'Tangani DISPUTE', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOrdersScreen(filter: 'DISPUTE')))),
                  _menu(context, Icons.account_balance_wallet_rounded, 'Pencairan Seller', 'Review permintaan withdrawal', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminWithdrawalsScreen()))),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _stat(String title, int value, IconData icon) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      Icon(icon, color: _blue),
      Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
      Text(title, style: const TextStyle(fontSize: 10)),
    ]),
  );

  Widget _menu(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: ListTile(
      onTap: onTap,
      leading: CircleAvatar(backgroundColor: _blue.withValues(alpha: .10), child: Icon(icon, color: _blue)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

class AdminInboxScreen extends StatelessWidget {
  const AdminInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox Chat')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('chats').orderBy('updatedAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Chat tidak dapat dimuat: ' + snapshot.error.toString()));
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) return const Center(child: Text('Belum ada chat.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, index) {
              final doc = docs[index];
              final data = doc.data();
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text((data['email'] ?? doc.id).toString()),
                subtitle: Text((data['lastMessage'] ?? '').toString(), maxLines: 1),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(chatId: doc.id, isAdmin: true))),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatAdminScreen extends StatelessWidget {
  const ChatAdminScreen({super.key});

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/6285642131263?text=Halo%20Admin%20Nusopa.Mart%2C%20saya%20butuh%20bantuan.');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Silakan masuk kembali.')));
    return Scaffold(
      appBar: AppBar(title: const Text('Bantuan Admin'), actions: [
        IconButton(icon: const Icon(Icons.headset_mic_rounded), onPressed: _openWhatsApp, tooltip: 'WhatsApp Admin'),
      ]),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFEAF3FF), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(Icons.headset_mic_rounded, color: _blue),
            const SizedBox(width: 10),
            const Expanded(child: Text('Chat online dengan Admin Nusopa.Mart')),
            TextButton(onPressed: _openWhatsApp, child: const Text('WHATSAPP')),
          ]),
        ),
        Expanded(child: ChatRoomScreen(chatId: uid, isAdmin: false, embedded: true)),
      ]),
    );
  }
}

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final bool isAdmin;
  final bool embedded;

  const ChatRoomScreen({super.key, required this.chatId, required this.isAdmin, this.embedded = false});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _text = TextEditingController();
  XFile? _image;
  bool _sending = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _messages =>
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages');

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (file != null && mounted) setState(() => _image = file);
  }

  Future<void> _send() async {
    if (_uid.isEmpty || (_text.text.trim().isEmpty && _image == null)) return;
    setState(() => _sending = true);
    try {
      String imageUrl = '';
      if (_image != null) {
        final ref = FirebaseStorage.instance.ref('chat/' + _uid + '/' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg');
        await ref.putFile(File(_image!.path));
        imageUrl = await ref.getDownloadURL();
      }
      final body = _text.text.trim();
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
        'ownerId': widget.isAdmin ? widget.chatId : _uid,
        'email': widget.isAdmin ? '' : FirebaseAuth.instance.currentUser?.email,
        'lastMessage': body.isEmpty ? '📷 Foto' : body,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _messages.add({
        'senderId': _uid,
        'text': body,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _text.clear();
      if (mounted) setState(() => _image = null);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messageList = StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _messages.orderBy('createdAt').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Pesan tidak dapat dimuat: ' + snapshot.error.toString()));
        final docs = snapshot.data?.docs ?? const [];
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, index) {
            final data = docs[index].data();
            final mine = data['senderId'] == _uid;
            return Align(
              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(10),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .76),
                decoration: BoxDecoration(color: mine ? _blue : Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if ((data['imageUrl'] ?? '').toString().isNotEmpty) Image.network(data['imageUrl'], height: 180, fit: BoxFit.cover),
                  if ((data['text'] ?? '').toString().isNotEmpty) Text(data['text'], style: TextStyle(color: mine ? Colors.white : Colors.black)),
                ]),
              ),
            );
          },
        );
      },
    );

    final input = SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          IconButton(onPressed: _pickImage, icon: const Icon(Icons.photo_camera_outlined)),
          Expanded(
            child: TextField(
              controller: _text,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(hintText: 'Tulis pesan...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(22))),
            ),
          ),
          IconButton(onPressed: _sending ? null : _send, icon: const Icon(Icons.send_rounded, color: _blue)),
        ]),
      ),
    );

    final content = Column(children: [Expanded(child: messageList), input]);
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: Text(widget.isAdmin ? 'Chat Pelanggan' : 'Chat Admin')),
      body: content,
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }
}

class AdminOrdersScreen extends StatelessWidget {
  final String filter;
  const AdminOrdersScreen({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(filter.replaceAll('_', ' '))),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: filter).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Order tidak dapat dimuat: ' + snapshot.error.toString()));
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) return const Center(child: Text('Tidak ada data.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, index) {
              final doc = docs[index];
              final data = doc.data();
              return ListTile(
                title: Text((data['productName'] ?? 'Produk').toString()),
                subtitle: Text('Rp' + (data['total'] ?? 0).toString()),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => doc.reference.update({'status': value, 'updatedAt': FieldValue.serverTimestamp()}),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'DIBAYAR', child: Text('DIBAYAR')),
                    PopupMenuItem(value: 'DIBATALKAN', child: Text('DIBATALKAN')),
                    PopupMenuItem(value: 'SELESAI', child: Text('SELESAI')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminWithdrawalsScreen extends StatelessWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdrawal')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('withdrawals').where('status', isEqualTo: 'MENUNGGU_ADMIN').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Withdrawal tidak dapat dimuat: ' + snapshot.error.toString()));
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) return const Center(child: Text('Tidak ada withdrawal.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, index) {
              final doc = docs[index];
              final data = doc.data();
              return ListTile(
                title: Text('Rp' + (data['amount'] ?? 0).toString()),
                subtitle: Text((data['bank'] ?? '').toString() + ' ' + (data['accountNumber'] ?? '').toString()),
                trailing: FilledButton(
                  onPressed: () => doc.reference.update({'status': 'DIPROSES', 'updatedAt': FieldValue.serverTimestamp()}),
                  child: const Text('PROSES'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
