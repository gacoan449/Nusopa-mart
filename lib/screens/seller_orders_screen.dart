import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sesi berakhir.')));
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Penjual')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').where('sellerId', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Pesanan tidak dapat dimuat: ' + snapshot.error.toString()));
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) return const Center(child: Text('Belum ada pesanan.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, index) {
              final doc = docs[index];
              final data = doc.data();
              return Card(
                child: ListTile(
                  title: Text((data['productName'] ?? 'Produk').toString()),
                  subtitle: Text('Status: ' + (data['status'] ?? '-').toString() + '\nTotal Rp' + (data['total'] ?? 0).toString()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SellerOrderDetail(id: doc.id, data: data))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SellerOrderDetail extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;
  const SellerOrderDetail({super.key, required this.id, required this.data});
  @override
  State<SellerOrderDetail> createState() => _SellerOrderDetailState();
}

class _SellerOrderDetailState extends State<SellerOrderDetail> {
  final courier = TextEditingController();
  final resi = TextEditingController();
  final cost = TextEditingController();
  XFile? photo;
  bool loading = false;

  Future<void> _update(String status) async {
    setState(() => loading = true);
    try {
      await FirebaseFirestore.instance.collection('orders').doc(widget.id).update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null && mounted) setState(() => photo = file);
  }

  Future<void> _ship() async {
    if (courier.text.trim().isEmpty || resi.text.trim().isEmpty) return;
    setState(() => loading = true);
    try {
      String url = '';
      if (photo != null) {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final ref = FirebaseStorage.instance.ref('shipping/' + uid + '/' + widget.id + '.jpg');
        await ref.putFile(File(photo!.path));
        url = await ref.getDownloadURL();
      }
      await FirebaseFirestore.instance.collection('orders').doc(widget.id).update({
        'courier': courier.text.trim(),
        'trackingNumber': resi.text.trim(),
        'shippingCost': int.tryParse(cost.text) ?? widget.data['shippingCost'] ?? 0,
        if (url.isNotEmpty) 'shippingProofUrl': url,
        'status': 'DIKIRIM',
        'shippedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.data['status'] ?? '').toString();
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Pesanan')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text((widget.data['productName'] ?? 'Produk').toString(), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Status saat ini: ' + status),
        const SizedBox(height: 18),
        if (status == 'DIBAYAR') FilledButton.icon(onPressed: loading ? null : () => _update('DIPROSES'), icon: const Icon(Icons.play_arrow), label: const Text('MULAI PROSES')),
        if (status == 'DIPROSES') FilledButton.icon(onPressed: loading ? null : () => _update('SIAP_DIKIRIM'), icon: const Icon(Icons.inventory_2), label: const Text('SIAP DIKIRIM')),
        if (['SIAP_DIKIRIM', 'DIPROSES'].contains(status)) ...[
          const SizedBox(height: 16),
          const Text('Data pengiriman'),
          TextField(controller: courier, decoration: const InputDecoration(labelText: 'Nama ekspedisi')),
          TextField(controller: resi, decoration: const InputDecoration(labelText: 'Nomor resi')),
          TextField(controller: cost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ongkir aktual')),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: _pick, icon: const Icon(Icons.photo_camera), label: Text(photo == null ? 'Foto resi/bukti pengiriman' : 'Foto dipilih')),
          const SizedBox(height: 10),
          FilledButton.icon(onPressed: loading ? null : _ship, icon: const Icon(Icons.local_shipping), label: const Text('SIMPAN & TANDAI DIKIRIM')),
        ],
      ]),
    );
  }

  @override
  void dispose() {
    courier.dispose();
    resi.dispose();
    cost.dispose();
    super.dispose();
  }
}
