import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatAdminScreen extends StatefulWidget {
  const ChatAdminScreen({super.key});

  @override
  State<ChatAdminScreen> createState() => _ChatAdminScreenState();
}

class _ChatAdminScreenState extends State<ChatAdminScreen> {
  final TextEditingController _pesanController = TextEditingController();
  
  // Data simulasi (dummy data) riwayat chat antara Seller dan Admin
  final List<Map<String, dynamic>> _riwayatChat = [
    {
      'isMe': true, // Dikirim oleh Seller
      'text': 'Halo min, kuota tiket admin toko saya habis (0). Boleh minta QRIS untuk beli 10 tiket?',
      'time': '10:00',
      'isImage': false,
    },
    {
      'isMe': false, // Dikirim oleh Admin (Anda)
      'text': 'Halo kak! Siap, ini QRIS manual Nusopa.Mart sebesar Rp 10.000 untuk 10 tiket ya. Silakan di-scan dan bayar via e-wallet/m-banking.',
      'time': '10:02',
      'isImage': false,
    },
    {
      'isMe': false, // Admin mengirim gambar QRIS
      'text': 'https://unsplash.com', // Simulasi gambar kode QRIS
      'time': '10:02',
      'isImage': true,
    },
    {
      'isMe': true,
      'text': 'Sudah saya bayar ya min, ini bukti transfernya. Tolong di-input manual tiketnya.',
      'time': '10:05',
      'isImage': false,
    },
    {
      'isMe': false,
      'text': 'Baik kak, pembayaran terverifikasi! 10 Tiket sudah di-input ke dasbor toko Anda. Silakan dicek kembali. Terima kasih!',
      'time': '10:07',
      'isImage': false,
    },
  ];

  void _kirimPesan() {
    if (_pesanController.text.trim().isNotEmpty) {
      setState(() {
        _riwayatChat.add({
          'isMe': true,
          'text': _pesanController.text,
          'time': '10:10',
          'isImage': false,
        });
      });
      _pesanController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5), // Latar belakang chat modern
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
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
                Text('Admin Nusopa.Mart', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text('Online', style: GoogleFonts.inter(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // 1. AREA RIWAYAT BALON CHAT (SCROLLABLE)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _riwayatChat.length,
              itemBuilder: (context, index) {
                final chat = _riwayatChat[index];
                final bool isMe = chat['isMe'];

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: chat['isImage'] ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFFFF5722) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: chat['isImage']
                        // Jika pesan berupa gambar QRIS dari Admin
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              chat['text'],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(color: Color(0xFFFF5722)),
                                );
                              },
                            ),
                          )
                        // Jika pesan teks biasa
                        : Text(
                            chat['text'],
                            style: GoogleFonts.inter(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),

          // 2. KOTAK INPUT TEKS KIRIM PESAN DI BAGIAN BAWAH
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            backgroundColor: Colors.white,
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
