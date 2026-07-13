import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _resiController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  String _ekspedisiTerpilih = 'J&T Express';
  bool _isLoading = false;

  final String _currentSellerId = "SELLER_ID_PANCINGAN";

  @override
  void dispose() {
    _resiController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _prosesKirimDanPotongTiketFirebase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final ticketDoc = FirebaseFirestore.instance
          .collection('tickets')
          .doc(_currentSellerId);

      final snapshot = await ticketDoc.get();

      if (!snapshot.exists ||
          (snapshot.data()?['sisaTiket'] ?? 0) < 1) {
        _notif(
          "Gagal! Saldo tiket admin Anda habis (0). Harap chat admin untuk isi ulang.",
        );
        return;
      }

      int sisaTiketLama = snapshot.data()?['sisaTiket'] ?? 0;
      int sisaTiketBaru = sisaTiketLama - 1;

      await ticketDoc.update({
        'sisaTiket': sisaTiketBaru,
      });

      await FirebaseFirestore.instance
          .collection('shippings')
          .add({
        'sellerId': _currentSellerId,
        'namaEkspedisi': _ekspedisiTerpilih,
        'nomorResi': _resiController.text.trim(),
        'linkCekLogistik': _linkController.text.trim(),
        'waktuKirim': FieldValue.serverTimestamp(),
      });

      _suksesDialog(sisaTiketBaru.toString());
    } catch (e) {
      _notif("Terjadi kesalahan sistem:\n$e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _notif(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan)),
    );
  }

  void _suksesDialog(String sisa) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Pengiriman Berhasil!"),
        content: Text(
          "Resi berhasil disimpan ke Firebase.\n\n"
          "1 tiket telah dipotong.\n"
          "Sisa tiket Anda: $sisa",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resiController.clear();
              _linkController.clear();
            },
            child: const Text(
              "OK",
              style: TextStyle(
                color: Color(0xFFFF5722),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Input Pengiriman Firebase",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF5722),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _resiController,
                      decoration: const InputDecoration(
                        labelText: "Nomor Resi Paket",
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty
                              ? "Wajib diisi"
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _linkController,
                      decoration: const InputDecoration(
                        labelText:
                            "Link Web Pelacakan",
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty
                              ? "Wajib diisi"
                              : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFFF5722),
                        ),
                        onPressed:
                            _prosesKirimDanPotongTiketFirebase,
                        child: const Text(
                          "Simpan Data & Potong Tiket",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
