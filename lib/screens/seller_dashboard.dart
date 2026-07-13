import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  final _formKey = GlobalKey<FormState>();
  final _resiController = TextEditingController();
  final _linkController = TextEditingController();
  String _ekspedisiTerpilih = 'J&T Express';
  bool _isLoading = false;

  // Simulasi ID Akun Seller Toko Anda yang sedang aktif jualan
  final String _currentSellerId = "SELLER_ID_PANCINGAN"; 

  Future<void> _prosesKirimDanPotongTiketFirebase() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      var ticketDoc = FirebaseFirestore.instance.collection('tickets').doc(_currentSellerId);
      var snapshot = await ticketDoc.get();

      if (!snapshot.exists || (snapshot.data()?['sisaTiket'] ?? 0) < 1) {
        _notif("Gagal! Saldo tiket admin Anda habis (0). Harap chat admin untuk isi ulang.");
        return;
      }

      int sisaTiketLama = snapshot.data()?['sisaTiket'];
      int sisaTiketBaru = sisaTiketLama - 1;

      // 1. Eksekusi Pengurangan 1 Tiket Seller di Cloud Firebase
      await ticketDoc.update({'sisaTiket': sisaTiketBaru});

      // 2. Simpan Data Resi Nyata Agar Pembeli Bisa Lacak di Chrome
      await FirebaseFirestore.instance.collection('shippings').add({
        'sellerId': _currentSellerId,
        'namaEkspedisi': _ekspedisiTerpilih,
        'nomorResi': _resiController.text,
        'linkCekLogistik': _linkController.text,
        'waktuKirim': FieldValue.serverTimestamp(),
      });

      _suksesDialog(sisaTicketBaru.toString());
    } catch (e) {
      _notif("Terjadi kesalahan sistem: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _notif(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  void _suksesDialog(String sisa) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pengiriman Berhasil!'),
        content: Text('Resi tersimpan di internet. 1 Tiket dipotong.\nSisa tiket aktif Anda: $sisa'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resiController.clear(); _linkController.clear();
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFFFF5722))),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Input Pengiriman Firebase', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18))),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5722)))
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _resiController,
                    decoration: const InputDecoration(labelText: 'Nomor Resi Paket'),
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _linkController,
                    decoration: const InputDecoration(labelText: 'Link Web Pelacakan (Contoh: https://jet.co.id)'),
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                      onPressed: _prosesKirimDanPotongTiketFirebase,
                      child: const Text('Simpan Data & Potong Tiket', style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }
}
