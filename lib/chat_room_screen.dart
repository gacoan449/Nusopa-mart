import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatRoomId; 
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

  // PERBAIKAN 1: Proteksi RAM ponsel agar aplikasi bebas dari lag memori (Memory Leak Fix)
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _kirimPesanTeks() async {
    final user = _auth.currentUser;
    if (user == null || _messageController.text.trim().isEmpty) return;

    String teksPesan = _messageController.text.trim();
    _messageController.clear();

    try {
      // 1. Simpan pesan baru ke sub-collection room chat
      await _firestore
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add({
        'sender_id': user.uid,
        'text': teksPesan,
        'timestamp': Timestamp.now(),
      });

      // 2. PERBAIKAN 3: Update info pesan terakhir dengan aman tanpa menimpa array users asli
      await _firestore.collection('chat_rooms').doc(widget.chatRoomId).update({
        'last_message': teksPesan,
        'last_update': Timestamp.now(),
      });
    } catch (e) {
      debugPrint("Gagal mengirim pesan: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    // Mengambil ukuran lebar maksimal chat agar responsif di HP kecil maupun besar
    double lebarMaksimalChat = MediaQuery.of(context).size.width * 0.75;

    return Scaffold(
      backgroundColor: Colors.grey.shade100, // PERBAIKAN 4: Latar belakang diselaraskan
      appBar: AppBar(
        title: Text(widget.namaLawanBicara, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.orange.shade800, // Tema Oranye Premium COD Nusopa
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // DAFTAR PESAN REALTIME
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chat_rooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Gagal memuat pesan: ${snapshot.error}', style: const TextStyle(fontSize: 12)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var messageDocs = snapshot.data!.docs;

                if (messageDocs.isEmpty) {
                  return const Center(
                    child: Text('Belum ada pesan. Silakan ajukan penawaran atau tanya stok produk.', 
                      style: TextStyle(color: Colors.grey, fontSize: 12)
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true, 
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  itemCount: messageDocs.length,
                  itemBuilder: (context, index) {
                    var data = messageDocs[index].data() as Map<String, dynamic>;
                    bool isMe = (data['sender_id'] == user?.uid);

                    // Ambil format waktu jam:menit pesan jika timestamp tersedia
                    String waktuKirim = "";
                    if (data['timestamp'] != null) {
                      Timestamp ts = data['timestamp'];
                      DateTime dt = ts.toDate();
                      waktuKirim = " ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      // PERBAIKAN 2: Batasi lebar bubble chat agar teks panjang tidak meluber dari layar
                      child: Container(
                        constraints: BoxConstraints(maxWidth: lebarMaksimalChat),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.orange.shade800 : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(isMe ? 12 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8), 
                              blurRadius: 2, 
                              offset: const Offset(0, 1)
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              data['text'] ?? '',
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 13.5,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Indikator jam kecil di pojok bawah bubble chat ala Shopee
                            Text(
                              waktuKirim,
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.grey,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // KOLOM MEMASUKKAN TEKS PESAN
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10), 
                    blurRadius: 4, 
                    offset: const Offset(0, -1)
                  )
                ]
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: "Ketik pesan untuk kesepakatan COD...",
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        backgroundColor: Colors.grey.shade100,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6), 
                          borderSide: BorderSide.none
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.orange.shade800,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 16),
                      onPressed: _kirimPesanTeks,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
