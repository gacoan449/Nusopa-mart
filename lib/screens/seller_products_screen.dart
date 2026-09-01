import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SellerProductsScreen extends StatelessWidget {
  const SellerProductsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sesi berakhir.')));
    return Scaffold(
      appBar: AppBar(title: const Text('Produk Saya')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductEditorScreen())), icon: const Icon(Icons.add), label: const Text('Produk')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('products').where('sellerId', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Produk tidak dapat dimuat: ' + snapshot.error.toString()));
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) return const Center(child: Text('Belum ada produk.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, index) {
              final doc = docs[index];
              final data = doc.data();
              final url = (data['imageUrl'] ?? '').toString();
              return ListTile(
                leading: url.isEmpty ? const Icon(Icons.image) : Image.network(url, width: 50, height: 50, fit: BoxFit.cover),
                title: Text((data['name'] ?? 'Produk').toString()),
                subtitle: Text('Rp' + (data['price'] ?? 0).toString() + ' • Stok ' + (data['stock'] ?? 0).toString()),
                trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => doc.reference.delete()),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductEditorScreen(id: doc.id, data: data))),
              );
            },
          );
        },
      ),
    );
  }
}

class ProductEditorScreen extends StatefulWidget {
  final String? id;
  final Map<String, dynamic>? data;
  const ProductEditorScreen({super.key, this.id, this.data});
  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  late final TextEditingController name;
  late final TextEditingController price;
  late final TextEditingController stock;
  late final TextEditingController description;
  XFile? image;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.data ?? {};
    name = TextEditingController(text: (data['name'] ?? '').toString());
    price = TextEditingController(text: (data['price'] ?? '').toString());
    stock = TextEditingController(text: (data['stock'] ?? '').toString());
    description = TextEditingController(text: (data['description'] ?? '').toString());
  }

  Future<void> pick() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null && mounted) setState(() => image = file);
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) return;
    setState(() => saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      String url = (widget.data?['imageUrl'] ?? '').toString();
      if (image != null) {
        final ref = FirebaseStorage.instance.ref('products/' + uid + '/' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg');
        await ref.putFile(File(image!.path));
        url = await ref.getDownloadURL();
      }
      final data = <String, dynamic>{
        'sellerId': uid,
        'name': name.text.trim(),
        'price': int.tryParse(price.text) ?? 0,
        'stock': int.tryParse(stock.text) ?? 0,
        'description': description.text.trim(),
        'imageUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (widget.id == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('products').add(data);
      } else {
        await FirebaseFirestore.instance.collection('products').doc(widget.id).update(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingUrl = (widget.data?['imageUrl'] ?? '').toString();
    return Scaffold(
      appBar: AppBar(title: Text(widget.id == null ? 'Tambah Produk' : 'Edit Produk')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        GestureDetector(
          onTap: pick,
          child: Container(
            height: 180,
            color: Colors.blue.shade50,
            child: image != null
                ? Image.file(File(image!.path), fit: BoxFit.cover)
                : existingUrl.isNotEmpty
                    ? Image.network(existingUrl, fit: BoxFit.cover)
                    : const Center(child: Icon(Icons.add_photo_alternate_outlined, size: 48)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama produk')),
        TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga')),
        TextField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok')),
        TextField(controller: description, maxLines: 4, decoration: const InputDecoration(labelText: 'Deskripsi')),
        const SizedBox(height: 20),
        FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'Menyimpan...' : 'SIMPAN')),
      ]),
    );
  }

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    stock.dispose();
    description.dispose();
    super.dispose();
  }
}
