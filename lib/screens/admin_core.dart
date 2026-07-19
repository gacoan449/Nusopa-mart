import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================================
// 1. KOKPIT SUPER ADMIN (HANYA DIAKSES OLEH CEO MELALUI LOGIN RAHASIA)
// ============================================================================

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  // Warna Khusus Mode Admin (Lebih gelap dan otoritatif)
  static const Color adminDark = Color(0xFF1A1A2E);
  static const Color adminAccent = Color(0xFFFF5722);
  static const Color dangerColor = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: adminDark,
        elevation: 0,
        title: Text(
          'Pusat Kendali Utama',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Keluar Mode Admin',
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KARTU RINGKASAN DATA
            Text('Ringkasan Hari Ini', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: adminDark)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard('Tiket Terjual', '342', Icons.confirmation_number, Colors.blue.shade700),
                _buildStatCard('Toko Dibekukan', '2', Icons.gavel, dangerColor),
                _buildStatCard('Antrean Mutasi', '14', Icons.pending_actions, Colors.orange.shade700),
                _buildStatCard('Omzet Kas (Rp)', '14.5M', Icons.account_balance_wallet, Colors.green.shade700),
              ],
            ),
            const SizedBox(height: 24),

            // MENU TINDAKAN KRITIKAL
            Text('Tindakan Cepat', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: adminDark)),
            const SizedBox(height: 12),
            // FIX: Mengganti Icons.store_off menjadi Icons.block
            _buildAdminMenu(Icons.block, 'Blacklist & Suspend Toko', 'Blokir toko penipu/melanggar aturan', dangerColor, context),
            _buildAdminMenu(Icons.verified, 'Verifikasi Top-Up Tiket', 'Setujui mutasi transfer penjual', Colors.blue.shade800, context),
            _buildAdminMenu(Icons.price_check, 'Pencairan Dana Penjual', 'Transfer saldo ke rekening penjual', Colors.green.shade800, context),
            _buildAdminMenu(Icons.admin_panel_settings, 'Log Aktivitas Sistem', 'Pantau arus keluar masuk aplikasi', adminDark, context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: Colors.grey.shade300)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildAdminMenu(IconData icon, String title, String subtitle, Color color, BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Membuka menu $title...')),
          );
        },
      ),
    );
  }
}

// ============================================================================
// 2. LAYAR CHAT PENGGUNA (DIAKSES OLEH PEMBELI/PENJUAL UNTUK HUBUNGI ADMIN)
// ============================================================================

class ChatAdminScreen extends StatefulWidget {
  const ChatAdminScreen({super.key});

  @override
  State<ChatAdminScreen> createState() => _ChatAdminScreenState();
}

class _ChatAdminScreenState extends State<ChatAdminScreen> {
  final TextEditingController _pesanController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // ID Sementara untuk testing (Nanti diganti dengan ID User aktif dari FirebaseAuth)
  final String _currentUserId = "USER_001"; 
  static const Color primaryColor = Color(0xFFFF5722);

  @override
  void dispose() {
    _pesanController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _hubungiWhatsAppCEO() async {
    // URL Encode teks pesan otomatis
    final Uri waUrl = Uri.parse("https://wa.me/6285642131263?text=Halo%20Admin%20Nusopa.Mart,%20saya%20butuh%20bantuan%20urgent.");
    try {
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Browser/WA tidak merespon.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp. Pastikan aplikasi terinstal.')),
        );
      }
    }
  }

  void _kirimPesan() async {
    final String teksPesan = _pesanController.text.trim();
    if (teksPesan.isEmpty) return;

    _pesanController.clear();

    // Simpan ke Firestore
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_currentUserId)
        .collection('messages')
        .add({
      'isMe': true,
      'text': teksPesan,
      'timestamp': FieldValue.serverTimestamp(),
      'isImage': false,
    });

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.1),
              child: const Icon(Icons.support_agent, color: primaryColor),
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
                  'Siap Membantu Anda',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.green.shade600, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // MENDENGAR CHAT DARI FIRESTORE
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_currentUserId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryColor));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada obrolan.\nKirim pesan untuk mulai bantuan.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
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
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        padding: isImage
                            ? const EdgeInsets.all(4)
                            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? primaryColor : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                          border: isMe ? null : Border.all(color: Colors.grey.shade200),
                        ),
                        child: isImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(text, fit: BoxFit.cover),
                              )
                            : Text(
                                text,
                                style: GoogleFonts.inter(color: isMe ? Colors.white : Colors.black87, fontSize: 14),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // BANNER SMART WA REDIRECT (Berada tepat di atas input chat)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border(top: BorderSide(color: Colors.orange.shade100)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade800, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Butuh respon cepat / Urgent?',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: _hubungiWhatsAppCEO,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat, size: 12),
                      const SizedBox(width: 4),
                      Text('Chat WA', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          // INPUT CHAT BAWAH
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
                          hintText: 'Tulis pesan Anda...',
                          hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _kirimPesan,
                    child: const CircleAvatar(
                      backgroundColor: primaryColor,
                      radius: 22,
                      child: Icon(Icons.send, color: Colors.white, size: 18),
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
