import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BantuanScreen extends StatefulWidget {
  const BantuanScreen({super.key});

  @override
  State<BantuanScreen> createState() => _BantuanScreenState();
}

class _BantuanScreenState extends State<BantuanScreen> {
  final TextEditingController _chatController = TextEditingController();
  
  // List obrolan menggunakan data reverse agar pesan terbaru selalu di bawah otomatis
  final List<Map<String, dynamic>> _messages = [
    {"text": "Halo! Saya Nusopa AI. Ada yang bisa saya bantu mengenai operasional aplikasi?", "isMe": false}
  ];

  final String nomorWaAdmin = "6285642131263"; 

  // PERBAIKAN 2: Proteksi Memori RAM HP agar aplikasi tidak lag (Memory Leak Fix)
  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  // PERBAIKAN 1: Struktur link WhatsApp diperbaiki total agar anti-crash dan langsung terbuka
  void _hubungiWhatsAppAdmin() async {
    String pesanPemicu = "Halo Admin Nusopa-mart, saya mengalami kendala pada transaksi/aplikasi saya. Mohon bantuannya.";
    final Uri url = Uri.parse("https://wa.me{Uri.encodeComponent(pesanPemicu)}");
    
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak dapat membuka aplikasi WhatsApp.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghubungkan: $e')),
        );
      }
    }
  }

  void _responAiOtomatis(String pesanUser) {
    String kataKunci = pesanUser.toLowerCase();
    String jawabanBot = "Maaf, saya belum memahami pertanyaan Anda. Anda bisa menekan tombol 'Hubungi Layanan WhatsApp Admin' di atas untuk berbicara langsung dengan pemilik aplikasi.";

    if (kataKunci.contains('tiket') || kataKunci.contains('top up') || kataKunci.contains('qris')) {
      jawabanBot = "Untuk melakukan isi ulang Tiket Jualan, silakan masuk ke menu 'Saya/Profil', lalu klik tombol 'BELI TIKET VIA QRIS ADMIN'. Silakan transfer sesuai nominal paket dan unggah bukti transfer agar disetujui admin.";
    } else if (kataKunci.contains('cod') || kataKunci.contains('bayar')) {
      jawabanBot = "Sistem pembayaran di Nusopa-mart 100% menggunakan COD (Bayar di Tempat). Pembeli menyerahkan uang tunai langsung ke seller/kurir saat paket fisik tiba di lokasi tujuan.";
    } else if (kataKunci.contains('resi') || kataKunci.contains('kirim') || kataKunci.contains('lacak')) {
      jawabanBot = "Penjual berkewajiban menginput foto resi fisik kurir setelah mengirim barang di gerai. Pembeli dapat memantau foto resi tersebut langsung di menu 'Status Transaksi'.";
    } else if (kataKunci.contains('admin') || kataKunci.contains('pemilik') || kataKunci.contains('nomor')) {
      jawabanBot = "Anda bisa langsung terhubung dengan Admin utama via WhatsApp dengan menekan kartu hijau 'Hubungi Layanan WhatsApp Admin' di bagian paling atas layar ini.";
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _messages.insert(0, {"text": jawabanBot, "isMe": false});
        });
      }
    });
  }

  void _kirimPesanChat() {
    if (_chatController.text.trim().isEmpty) return;
    String teksUser = _chatController.text.trim();
    _chatController.clear();

    setState(() {
      _messages.insert(0, {"text": teksUser, "isMe": true});
    });

    _responAiOtomatis(teksUser);
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil ukuran lebar layar HP agar bubble chat responsif
    double lebarMaksimalChat = MediaQuery.of(context).size.width * 0.75;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Pusat Bantuan & Nusopa AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.orange.shade800, // PERBAIKAN 4: Tema Oranye Selaras
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // KOTAK PINTAS HUBUNGI WA ADMIN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Card(
              color: Colors.emerald.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.emerald.shade200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.emerald.shade600,
                  child: const Icon(Icons.chat, color: Colors.white, size: 20),
                ),
                title: const Text('Hubungi Layanan WhatsApp Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.emerald)),
                subtitle: Text('Bicara langsung ke nomor 085642131263 jika ada kendala darurat / top-up tiket.', style: TextStyle(fontSize: 11, color: Colors.emerald.shade900)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.emerald),
                onTap: _hubungiWhatsAppAdmin,
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Text('ASISTEN MANDIRI NUSOPA AI', style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),

          // RUANG OBROLAN CHATBOT AI (PERBAIKAN 3: Proteksi Meluber di Layar HP)
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                var msg = _messages[index];
                bool isMe = msg['isMe'];

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
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
                        BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 2, offset: const Offset(0, 1))
                      ],
                    ),
                    child: Text(
                      msg['text'],
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87, 
                        fontSize: 13, 
                        height: 1.3
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // KOLOM INPUT CHAT BOT AI
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4, offset: const Offset(0, -1))]
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Tanya AI (Contoh: cara isi tiket, sistem cod)...",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        backgroundColor: Colors.grey.shade100,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.orange.shade800),
                    onPressed: _kirimPesanChat,
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
