import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatRoomId; // ID unik gabungan UID Pembeli & Penjual
  final String namaLawanBicara;

  const ChatRoomScreen({
    super.key,
    required this.chatRoomId,
    required this.namaLawanBicara,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fungsi mengirim pesan ke Firestore cloud
  void _kirimPesanTeks() async {
    final user = _auth.currentUser;
    if (user == null || _messageController.text.trim().isEmpty) return;

    String teksPesan = _messageController.text.trim();
    _messageController.clear();

    // 1. Simpan pesan ke sub-collection di dalam room chat
    await _firestore
        .collection('chat_rooms')
        .doc(widget.chatRoomId)
        .collection('messages')
        .add({
      'sender_id': user.uid,
      'text': teksPesan,
      'timestamp': Timestamp.now(),
    });

    // 2. Update info terakhir di dokumen utama room chat untuk halaman daftar chat
    await _firestore.collection('chat_rooms').doc(widget.chatRoomId).set({
      'last_message': teksPesan,
      'last_update': Timestamp.now(),
      'users': widget.chatRoomId.split('_'), // Berisi [uid_pembeli, uid_penjual]
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.blue.shade50, // Latar belakang chat biru soft
      appBar: AppBar(
        title: Text(widget.namaLawanBicara),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // DAFTAR PESAN YANG MUNCUL (STREAMBUILDER REALTIME)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chat_rooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var messageDocs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Menampilkan pesan terbaru dari bawah
                  padding: const EdgeInsets.all(16),
                  itemCount: messageDocs.length,
                  itemBuilder: (context, index) {
                    var data = messageDocs[index].data() as Map<String, dynamic>;
                    bool isMe = (data['sender_id'] == user?.uid);

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue.shade600 : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(isMe ? 12 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 12),
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 2, spreadRadius: 0.5)
                          ],
                        ),
                        child: Text(
                          data['text'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // KOLOM BAWAH TEMPAT MENGETIK PESAN
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Ketik pesan untuk kesepakatan COD...",
                      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: Colors.grey.shade100,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue.shade700,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _kirimPesanTeks,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
