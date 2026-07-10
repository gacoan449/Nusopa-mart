import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // Fungsi menyetujui tiket seller (Gunakan Firestore Transaction agar aman)
  void _setujuiTiket(BuildContext context, String requestId, String sellerId, int jumlahTiketDiminta) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      await firestore.runTransaction((transaction) async {
        DocumentReference requestRef = firestore.collection('topup_tickets').doc(requestId);
        DocumentReference sellerRef = firestore.collection('users').doc(sellerId);

        // 1. Ambil data kuota tiket terakhir si seller
        DocumentSnapshot sellerSnapshot = await transaction.get(sellerRef);
        int kuotaSekarang = sellerSnapshot['kuota_tiket'] ?? 0;

        // 2. Update status pengajuan jadi 'disetujui' dan tambahkan tiket seller
        transaction.update(requestRef, {'status': 'disetujui'});
        transaction.update(sellerRef, {'kuota_tiket': kuotaSekarang + jumlahTiketDiminta});
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sukses! Tiket berhasil ditambahkan ke saldo seller.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyetujui: $e')));
      }
    }
  }

  // Fungsi menolak pengajuan tiket jika bukti transfer palsu/tidak masuk
  void _tolakTiket(BuildContext context, String requestId) async {
    await FirebaseFirestore.instance.collection('topup_tickets').doc(requestId).update({
      'status': 'ditolak',
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan tiket telah ditolak.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Dashboard Utama Admin (Nusopa)'),
        backgroundColor: Colors.red.shade800, // Warna merah tegas khusus admin
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Membaca semua request tiket yang berstatus 'pending' dari database
        stream: FirebaseFirestore.instance
            .collection('topup_tickets')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 50, color: Colors.green),
                  SizedBox(height: 10),
                  Text('Semua beres! Tidak ada antrean top-up tiket.'),
                ],
              ),
            );
          }

          var requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var reqId = requests[index].id;
              var data = requests[index].data() as Map<String, dynamic>;
              
              String namaToko = data['nama_toko'] ?? 'Toko Tanpa Nama';
              String paket = data['paket_pilihan'] ?? '';
              int jumlahTiket = data['jumlah_tiket_diminta'] ?? 0;
              String buktiUrl = data['bukti_transfer_url'] ?? '';
              String sellerId = data['seller_id'] ?? '';

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.bottom(12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🏬 Toko: $namaToko', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('📦 Paket: $paket ($jumlahTiket Tiket)', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      
                      // Menampilkan Foto Bukti Transfer QRIS dari Seller
                      const Text('📸 Bukti Transfer QRIS:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          buktiUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 100,
                            color: Colors.grey.shade200,
                            child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      
                      // Tombol Aksi Admin (Setuju / Tolak)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, side: BorderSide(color: Colors.red.shade700)),
                              onPressed: () => _tolakTiket(context, reqId),
                              child: const Text('TOLAK'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                              onPressed: () => _setujuiTiket(context, reqId, sellerId, jumlahTiket),
                              child: const Text('SETUJUI & ISI TIKET'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
