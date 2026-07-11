import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import '../services/jarak_service.dart'; 

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

  // PERBAIKAN 2: Proteksi memori HP dari kebocoran RAM (Memory Leak Protection)
  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pilihGambarDagangan() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.orange.shade800),
                title: const Text('Ambil dari Galeri HP', style: TextStyle(fontSize: 13)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedFile = await _picker.pickImage(
                    source: ImageSource.gallery, 
                    imageQuality: 70, // Kompresi gambar agar hemat kuota storage cloud
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _imageFile = File(pickedFile.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.orange.shade800),
                title: const Text('Potret Langsung via Kamera HP', style: TextStyle(fontSize: 13)),
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

  void _simpanProdukKeFirestore() async {
    if (!_formKey.currentState!.validate() || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text('Mohon lengkapi data dan foto produk terlebih dahulu!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Validasi saldo tiket sebelum upload jualan
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      int sisaTiket = 0;
      String namaKotaSeller = "Lokal";
      
      if (userDoc.exists && userDoc.data() != null) {
        var uData = userDoc.data() as Map<String, dynamic>;
        sisaTiket = uData['kuota_tiket'] ?? 0;
        namaKotaSeller = uData['kota_seller'] ?? 'Lokal';
      }

      // PERBAIKAN 4: Proteksi reset loading jika tiket seller habis agar aplikasi tidak hang
      if (sisaTiket <= 0) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Colors.red, content: Text('Gagal! Tiket jualan Anda habis (0). Silakan isi tiket via QRIS Admin.')),
          );
        }
        return; 
      }

      // 2. Tangkap koordinat GPS akurat toko seller saat ini
      Position? posisiToko = await JarakService.ambilLokasiSekarang();
      double latitudeToko = posisiToko != null ? posisiToko.latitude : 0.0;
      double longitudeToko = posisiToko != null ? posisiToko.longitude : 0.0;

      // 3. Unggah file gambar ke cloud storage
      String namaFile = 'products/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(namaFile);
      UploadTask uploadTask = storageRef.putFile(_imageFile!);
      TaskSnapshot storageSnapshot = await uploadTask;
      String downloadUrl = await storageSnapshot.ref.getDownloadURL();

      // 4. PERBAIKAN 3: Sinkronisasi nama kunci field (lat_seller, lng_seller, foto_produk) sesuai beranda
      await FirebaseFirestore.instance.collection('products').add({
        'seller_id': user.uid,
        'nama_produk': _namaController.text.trim(),
        'harga': int.parse(_hargaController.text.trim()),
        'deskripsi': _deskripsiController.text.trim(),
        'foto_produk': downloadUrl, 
        'lat_seller': latitudeToko,   
        'lng_seller': longitudeToko,  
        'kota_seller': namaKotaSeller,
        'rating': 5.0, // Default barang baru otomatis bintang 5
        'dibuat_pada': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('Produk baru berhasil dipajang di Beranda aplikasi!')),
        );
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Terjadi error saat upload: $e')),
        );
      }
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
      backgroundColor: Colors.grey.shade50,
      // PERBAIKAN 5: Warna AppBar diselaraskan oranye premium
      appBar: AppBar(
        title: const Text('Tambah Produk Dagangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 14),
                  Text('Menangkap koordinat GPS toko & mengunggah data...', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Foto Produk Dagangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pilihGambarDagangan,
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade200, width: 1),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(_imageFile!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.orange.shade800),
                                  const SizedBox(height: 6),
                                  const Text('Ketuk untuk ambil foto / galeri HP', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Detail Informasi Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 8),
                    
                    // PERBAIKAN 1: Melengkapi penutupan form teks gantung & pembungkus input data utuh
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: Colors.grey.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _namaController,
                              style: const TextStyle(fontSize: 13),
