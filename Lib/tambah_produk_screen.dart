import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import '../services/jarak_service.dart'; // Mengimpor utilitas hitung jarak GPS

class TambahProdukScreen extends StatefulWidget {
  const TambahProdukScreen({super.key});

  @override
  State<TambahProdukScreen> createState() => _TambahProdukScreenState();
}

class _TambahProdukScreenState extends State<TambahProdukScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // UPGRADE: Fungsi pintar memunculkan opsi Kamera Fisik atau Galeri HP
  Future<void> _pilihGambarDagangan() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Ambil dari Galeri HP'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedFile = await _picker.pickImage(
                    source: ImageSource.gallery, 
                    imageQuality: 70,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _imageFile = File(pickedFile.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.orange),
                title: const Text('Potret Langsung via Kamera Fisik'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedFile = await _picker.pickImage(
                    source: ImageSource.camera, 
                    imageQuality: 70,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _imageFile = File(pickedFile.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Fungsi utama validasi kuota tiket, rekam koordinat GPS, dan upload produk
  void _simpanProdukKeFirestore() async {
    if (!_formKey.currentState!.validate() || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua data dan foto produk terlebih dahulu!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. CEK KUOTA TIKET SELLER TERLEBIH DAHULU
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      int sisaTiket = userDoc['kuota_tiket'] ?? 0;

      if (sisaTiket <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal! Tiket jualan Anda habis (0). Silakan isi tiket via QRIS Admin di menu Profil.')),
          );
        }
        return;
      }

      // 2. UPGRADE: Tangkap Titik Koordinat GPS Toko Seller Saat Ini
      Position? posisiToko = await JarakService.ambilLokasiSekarang();
      double latitudeToko = posisiToko != null ? posisiToko.latitude : 0.0;
      double longitudeToko = posisiToko != null ? posisiToko.longitude : 0.0;

      // 3. UNGGAH FOTO PRODUK KE FIREBASE STORAGE
      String namaFile = 'products/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(namaFile);
      UploadTask uploadTask = storageRef.putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 4. SIMPAN DATA LENGKAP + KOORDINAT GPS KE FIRESTORE
      await FirebaseFirestore.instance.collection('products').add({
        'seller_id': user.uid,
        'nama_produk': _namaController.text.trim(),
        'harga': int.parse(_hargaController.text.trim()),
        'deskripsi': _deskripsiController.text.trim(),
        'foto_url': downloadUrl,
        'latitude': latitudeToko,   // Menyimpan data garis lintang gps
        'longitude': longitudeToko, // Menyimpan data garis bujur gps
        'jarak': '0.0 km',          // Nilai dasar (akan dikalkulasi dinamis di beranda pembeli)
        'dibuat_pada': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk baru berhasil dipajang di Beranda aplikasi!')),
        );
        Navigator.pop(context); // Kembali ke halaman profil
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi error saat upload: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Tambah Produk Dagangan'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 15),
                Text('Menangkap titik GPS & mengunggah data ke awan...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KOTAK SELECT FOTO PRODUK
                    const Text('Foto Produk Dagangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pilihGambarDagangan,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, width: 1),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_imageFile!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, size: 45, color: Colors.blue.shade700),
                                  const SizedBox(height: 8),
                                  const Text('Ketuk untuk foto langsung atau ambil dari galeri HP', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // FORM ISI DATA TEKS
                    const Text('Detail Informasi Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _namaController,
                              decoration: const InputDecoration(labelText: 'Nama Barang Dagangan', border: UnderlineInputBorder()),
                              validator: (val) => val!.isEmpty ? 'Nama produk wajib diisi' : null,
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _hargaController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Harga Jual Sistem COD (Rp)', prefixText: 'Rp ', border: UnderlineInputBorder()),
                              validator: (val) => val!.isEmpty ? 'Harga produk wajib diisi' : null,
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _deskripsiController,
                              maxLines: 3,
                              decoration: const InputDecoration(labelText: 'Deskripsi Produk Lengkap', border: UnderlineInputBorder()),
                              validator: (val) => val!.isEmpty ? 'Deskripsi barang wajib diisi' : null,
                            ),
                          ],
                        ),
