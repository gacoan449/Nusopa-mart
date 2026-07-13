import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatAdminScreen extends StatefulWidget {
  const ChatAdminScreen({super.key});

  @override
  State<ChatAdminScreen> createState() => _ChatAdminScreenState();
}

class _ChatAdminScreenState extends State<ChatAdminScreen> {
  final TextEditingController _pesanController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Simulasi ID Toko/Seller (Bisa diganti dengan ID dari FirebaseAuth nanti)
  final String _shopId = "TOKO_NUSOPA_01"; 

  @override
  void dispose() {
    _pesanController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Fungsi untuk mengirim pesan teks asli ke Firebase Firestore
  void _kirimPesan() async {
    final String teksPesan = _pesanController.text.trim();
    if (teksPesan.isEmpty) return;

    _pesanController.clear();

    // Menyimpan data ke koleksi 'chats' di Firestore secara langsung
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_shopId)
        .collection('messages')
        .add({
      'isMe': true, // True berarti dikirim oleh Seller/User saat ini
      'text': teksPesan,
      'timestamp': FieldValue.serverTimestamp(),
      'isImage': false,
    });

    // Otomatis scroll ke pesan paling bawah
    _scrollBawah();
  }

  void _scrollBawah() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFFF5722).withOpacity(0.1),
              child: const Icon(Icons.support_agent, color: Color(0xFFFF5722)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Nusopa.Mart',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Online',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Mendengar perubahan chat secara real-time dari database Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_shopId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5722)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Belum ada chat.\nSilakan hubungi admin jika ingin top-up tiket.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                
                // Memicu scroll otomatis ke bawah setiap kali ada pesan baru masuk
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollBawah());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final chat = docs[index].data() as Map<String, dynamic>;
                    final bool isMe = chat['isMe'] ?? true;
                    final bool isImage = chat['isImage'] ?? false;
                    final String text = chat['text'] ?? '';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: isImage
                            ? const EdgeInsets.all(4)
                            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFFF5722) : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                        ),
                        child: isImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  text,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Tampilan QRIS manual jika link dari dashboard dikirim oleh admin
                                    return Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.qr_code_2, size: 140, color: Color(0xFFFF5722)),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Scan QRIS GOPAY Admin',
                                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Text(
                                text,
                                style: GoogleFonts.inter(
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
          
          // INPUT CHAT UTAMA DI BAGIAN BAWAH SCREEN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _pesanController,
                        decoration: InputDecoration(
                          hintText: 'Tulis pesan ke admin...',
                          hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _kirimPesan,
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFFFF5722),
                      child: Icon(Icons.send, color: Colors.white, size: 20),
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
