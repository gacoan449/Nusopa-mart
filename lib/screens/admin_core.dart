import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

// ============================================================================
// 1. KOKPIT SUPER ADMIN (HANYA DIAKSES OLEH CEO MELALUI LOGIN RAHASIA)
// ============================================================================

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  // --- STATE REAL-TIME (Disiapkan untuk nyedot data dari Firebase/API) ---
  int _tiketTerjual = 0;
  int _tokoDibekukan = 0;
  int _antreanMutasi = 0;
  double _omzetKas = 0.0;
  bool _isLoading = true;

  // Konstanta Warna Tema Mewah (Navy & Putih)
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color secondaryBlue = Color(0xFF283593);
  static const Color textDark = Color(0xFF1E293B);
  static const Color dangerColor = Color(0xFFB91C1C);
  static const Color bgCanvas = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // Fungsi sinkronisasi data dari backend (Simulasi API Call)
  Future<void> _fetchDashboardData() async {
    // TODO: Ganti dengan Firebase fetch atau API GET lu di sini
    await Future.delayed(const Duration(milliseconds: 1200));
    
    if (mounted) {
      setState(() {
        _tiketTerjual = 342; // Hasil fetch DB
        _tokoDibekukan = 2; // Hasil fetch DB
        _antreanMutasi = 14; // Hasil fetch DB
        _omzetKas = 14500000.0; // Hasil fetch DB
        _isLoading = false;
      });
    }
  }

  String _formatRupiah(double amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  void _notif(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCanvas,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Pusat Kendali Utama',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Refresh Data',
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchDashboardData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Keluar Mode Admin',
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryBlue))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KARTU RINGKASAN DATA
                Text('Ringkasan Real-Time', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildStatCard('Tiket Terjual', _tiketTerjual.toString(), Icons.confirmation_number_outlined, Colors.blue.shade700),
                    _buildStatCard('Toko Dibekukan', _tokoDibekukan.toString(), Icons.block, dangerColor),
                    _buildStatCard('Antrean Mutasi', _antreanMutasi.toString(), Icons.pending_actions, Colors.orange.shade700),
                    _buildStatCard('Omzet Kas', _formatRupiah(_omzetKas), Icons.account_balance_wallet_outlined, Colors.teal.shade700),
                  ],
                ),
                const SizedBox(height: 24),

                // MENU TINDAKAN KRITIKAL
                Text('Tindakan Cepat & Moderasi', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
                const SizedBox(height: 12),
                
                // Tambahan Menu Spesifik untuk Cek Chat yang Masuk
                _buildAdminMenu(
                  icon: Icons.forum_outlined, 
                  title: 'Inbox Keluhan & Chat', 
                  subtitle: 'Balas pesan pembeli dan penjual', 
                  color: primaryBlue, 
                  onTap: () => _notif("Membuka daftar antrean chat Firestore...")
                ),
                _buildAdminMenu(
                  icon: Icons.price_check, 
                  title: 'Pencairan Dana Penjual', 
                  subtitle: 'Transfer mutasi saldo PPOB ke rekening penjual', 
                  color: Colors.teal.shade700, 
                  onTap: () => _notif("Membuka antrean pencairan dana...")
                ),
                _buildAdminMenu(
                  icon: Icons.verified, 
                  title: 'Verifikasi Top-Up Tiket', 
                  subtitle: 'Setujui mutasi transfer tiket penjual', 
                  color: Colors.blue.shade700, 
                  onTap: () => _notif("Membuka validasi mutasi tiket...")
                ),
                _buildAdminMenu(
                  icon: Icons.block, 
                  title: 'Blacklist & Suspend Toko', 
                  subtitle: 'Blokir toko penipu atau yang melanggar', 
                  color: dangerColor, 
                  onTap: () => _notif("Membuka manajemen suspend toko...")
                ),
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
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
        ],
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
          Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildAdminMenu({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
            title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: textDark)),
            subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ),
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
  
  // ID Sementara untuk auth. (Nanti ambil dari FirebaseAuth.instance.currentUser!.uid)
  final String _currentUserId = "USER_UID_REAL"; 
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color bgCanvas = Color(0xFFF8FAFC);

  @override
  void dispose() {
    _pesanController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _hubungiWhatsAppCEO() async {
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
          SnackBar(
            content: Text('Tidak dapat membuka WhatsApp. Pastikan aplikasi terinstal.', style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  void _kirimPesan() async {
    final String teksPesan = _pesanController.text.trim();
    if (teksPesan.isEmpty) return;

    _pesanController.clear();

    // Push ke Firestore (Ini beneran nulis ke DB lu kalau Firebase udah dikonfigurasi)
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_currentUserId)
        .collection('messages')
        .add({
      'isMe': true, // True berarti dikirim oleh User
      'text': teksPesan,
      'timestamp': FieldValue.serverTimestamp(),
      'isImage': false,
    });

    // Opsional: Update lastMessage di document utama buat nampilin list antrean di sisi Admin
    await FirebaseFirestore.instance.collection('chats').doc(_currentUserId).set({
      'lastMessage': teksPesan,
      'lastUpdated': FieldValue.serverTimestamp(),
      'unreadAdmin': true, 
    }, SetOptions(merge: true));

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
      backgroundColor: bgCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        iconTheme: const IconThemeData(color: primaryBlue),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: primaryBlue.withOpacity(0.1),
              child: const Icon(Icons.support_agent, color: primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Pusat',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: primaryBlue),
                ),
                Text(
                  'Online • Siap Membantu',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.teal.shade600, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // BANNER SMART WA REDIRECT (Warna disesuaikan agar tidak norak)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: primaryBlue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kendala urgent? Hubungi via WA.',
                    style: GoogleFonts.inter(fontSize: 12, color: primaryBlue, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: _hubungiWhatsAppCEO,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat, size: 12),
                      const SizedBox(width: 4),
                      Text('WA Admin', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          ),

          // LIST CHAT DARI FIRESTORE SECARA REALTIME
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
                  return const Center(child: CircularProgressIndicator(color: primaryBlue));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Sampaikan kendala Anda di sini.\nAdmin akan merespon secepatnya.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                // Trigger auto-scroll setiap ada pesan baru
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
                            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? primaryBlue : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                          border: isMe ? null : Border.all(color: Colors.grey.shade200),
                          boxShadow: isMe ? [
                            BoxShadow(color: primaryBlue.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))
                          ] : [],
                        ),
                        child: isImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(text, fit: BoxFit.cover),
                              )
                            : Text(
                                text,
                                style: GoogleFonts.inter(
                                  color: isMe ? Colors.white : const Color(0xFF1E293B), 
                                  fontSize: 14, 
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // INPUT CHAT BAWAH
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
              ]
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgCanvas,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _pesanController,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ketik pesan di sini...',
                          hintStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _kirimPesan(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _kirimPesan,
                    child: const CircleAvatar(
                      backgroundColor: primaryBlue,
                      radius: 24,
                      child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
