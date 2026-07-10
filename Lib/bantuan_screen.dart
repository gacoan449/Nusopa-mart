import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BantuanScreen extends StatefulWidget {
  const BantuanScreen({super.key});

  @override
  State<BantuanScreen> createState() => _BantuanScreenState();
}

class _BantuanScreenState extends State<BantuanScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {"text": "Halo! Saya Nusopa AI. Ada yang bisa saya bantu mengenai operasional aplikasi?", "isMe": false}
  ];

  // Sudah menggunakan nomor WA Anda dengan format internasional yang valid
  final String nomorWaAdmin = "6285642131263"; 

  // Fungsi menembak langsung ke aplikasi WhatsApp Anda
  void _hubungiWhatsAppAdmin() async {
    String pesanPemicu = "Halo Admin Nusopa-mart, saya mengalami kendala pada transaksi/aplikasi saya. Mohon bantuannya.";
    final Uri url = Uri.parse("https://wa.me{Uri.encodeComponent(pesanPemicu)}");
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka aplikasi WhatsApp.')),
        );
      }
    }
  }

  // Fungsi Kecerdasan Buatan Bot (AI Sederhana Mandiri Tanpa API Berbayar)
  void _responAiOtomatis(String pesanUser) {
    String kataKunci = pesanUser.toLowerCase();
    String jawabanBot = "Maaf, saya belum memahami pertanyaan Anda. Anda bisa menekan tombol 'Hubungi WA Admin' di atas untuk berbicara langsung dengan pemilik aplikasi.";

    if (kataKunci.contains('tiket') || kataKunci.contains('top up') || kataKunci.contains('qris')) {
      jawabanBot = "To melakukan isi ulang Tiket Jualan, silakan masuk ke menu 'Saya/Profil', lalu klik tombol 'BELI TIKET VIA QRIS ADMIN'. Silakan transfer sesuai nominal paket dan unggah bukti transfer agar disetujui admin.";
    } else if (kataKunci.contains('cod') || kataKunci.contains('bayar')) {
      jawabanBot = "Sistem pembayaran di Nusopa-mart 100% menggunakan COD (Bayar di Tempat). Pembeli menyerahkan uang tunai langsung ke kurir saat paket fisik tiba di rumah.";
    } else if (kataKunci.contains('resi') || kataKunci.contains('kirim') || kataKunci.contains('lacak')) {
      jawabanBot = "Penjual berkewajiban menginput nomor resi manual setelah mengirim barang. Pembeli dapat melacak paket dengan menekan tombol 'Lacak Paket' di menu Status Transaksi.";
    } else if (kataKunci.contains('admin') || kataKunci.contains('pemilik') || kataKunci.contains('nomor')) {
      jawabanBot = "Anda bisa langsung terhubung dengan Admin utama via WhatsApp dengan menekan tombol biru 'HUBUNGI WA ADMIN' di bagian atas layar ini.";
    }

    Future.delayed(const Duration(milliseconds: 600), () {
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
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Pusat Bantuan & AI'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. KOTAK PINTAS HUBUNGI WA ADMIN (MENGGUNAKAN NOMOR ANDA)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Card(
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.green.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.phone, color: Colors.white),
                ),
                title: const Text('Hubungi Layanan WhatsApp Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                subtitle: const Text('Berbicara langsung dengan pengembang ke nomor 085642131263 jika ada kendala darurat.', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.green),
                onTap: _hubungiWhatsAppAdmin,
              ),
            ),
          ),
          
          // Pembatas visual heading chat bot
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('--- OBROLAN MANDIRI NUSOPA AI ---', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
          ),

          // 2. RUANG OBROLAN CHATBOT AI
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                var msg = _messages[index];
                bool isMe = msg['isMe'];

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue.shade600 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg['text'],
                      style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 13),
                    ),
                  ),
                );
              },
            ),
          ),

          // KOLOM INPUT CHAT BOT AI
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: "Tanya AI (Contoh: cara isi tiket, sistem cod)...",
                      hintStyle: const TextStyle(fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: Colors.grey.shade100,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue.shade700),
                  onPressed: _kirimPesanChat,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
