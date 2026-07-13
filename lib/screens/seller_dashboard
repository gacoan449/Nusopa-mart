import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // Library koneksi internet nyata

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
  File? _fotoResiFisik;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // ⚠️ GANTI DENGAN URL IP VPS / DOMAIN BACKEND INTERNET ANDA NANTI
  final String _baseApiUrl = "http://10.0.2";

  final List<String> _daftarEkspedisi = [
    'J&T Express', 'JNE Express', 'SiCepat Ekspres', 'Pos Indonesia', 'Wahana'
  ];

  Future<void> _pilihSumberFoto(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 60);
    if (pickedFile != null) {
      setState(() => _fotoResiFisik = File(pickedFile.path));
    }
  }

  void _tampilkanPilihanFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFFF5722)),
              title: Text('Ambil via Kamera', style: GoogleFonts.inter()),
              onTap: () { Navigator.pop(context); _pilihSumberFoto(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFFF5722)),
              title: Text('Pilih dari Galeri', style: GoogleFonts.inter()),
              onTap: () { Navigator.pop(context); _pilihSumberFoto(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  // PROSES KIRIM DATA NYATA KE SEVER BACKEND
  Future<void> _kirimPengirimanNyata() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fotoResiFisik == null) {
      _notifikasi("Harap upload foto bukti resi fisik!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Karena kita mengirim file gambar, kita wajib menggunakan MultipartRequest
      var request = http.MultipartRequest('POST', Uri.parse(_baseApiUrl));
      
      // Mengisi form teks data pengiriman paket
      request.fields['orderId'] = "TRX-99201"; // Simulasi ID Transaksi target
      request.fields['namaEkspedisi'] = _ekspedisiTerpilih;
      request.fields['nomorResi'] = _resiController.text;
      request.fields['linkCekLogistik'] = _linkController.text;

      // Mengunggah file gambar resi fisik asli
      request.files.add(await http.MultipartFile.fromPath('fotoResi', _fotoResiFisik!.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var result = jsonDecode(responseData);

      if (response.statusCode == 200 && result['success'] == true) {
        _suksesDialog(result['sisaTiketAktif'].toString());
      } else {
        _notifikasi(result['message'] ?? "Gagal memproses pengiriman.");
      }
    } catch (e) {
      _notifikasi("Gagal terhubung ke server internet: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _notifikasi(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  void _suksesDialog(String sisaTiket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Pengiriman Sukses!', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Resi asli telah dikirim ke pembeli.\n\nSistem memotong 1 tiket. Sisa tiket toko Anda: $sisaTiket'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resiController.clear();
              _linkController.clear();
              setState(() => _fotoResiFisik = null);
            },
            child: const Text('Selesai', style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Input Pengiriman Nyata', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18))),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5722)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _ekspedisiTerpilih,
                    items: _daftarEkspedisi.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _ekspedisiTerpilih = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _resiController,
                    decoration: const InputDecoration(labelText: 'Nomor Resi Paket'),
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _linkController,
                    decoration: const InputDecoration(labelText: 'Tautan Web Cek Resi (Contoh: https://jet.co.id)'),
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _tampilkanPilihanFoto,
                    child: Container(
                      height: 150, width: double.infinity,
                      color: Colors.grey.shade200,
                      child: _fotoResiFisik != null 
                        ? Image.file(_fotoResiFisik!, fit: BoxFit.cover)
                        : const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                      onPressed: _kirimPengirimanNyata,
                      child: const Text('Kirim & Potong 1 Tiket', style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }
}
