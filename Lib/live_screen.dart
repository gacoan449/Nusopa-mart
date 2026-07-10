import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  // SISI SELLER: Fungsi mengaktifkan room live streaming di Firebase
  void _mulaiLiveStreaming(BuildContext context, String uid, String namaToko) async {
    final docRef = FirebaseFirestore.instance.collection('live_streams').doc(uid);
    
    await docRef.set({
      'seller_id': uid,
      'nama_toko': namaToko,
      'status': 'streaming',
      'dibuat_pada': Timestamp.now(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Siaran Langsung Dimulai! Kamera HP Anda kini menyiarkan produk.')),
      );
      // Di sini nanti tempat integrasi SDK Video View (Agora/Zego) untuk menangkap kamera
    }
  }

  // SISI SELLER: Fungsi mematikan live streaming
  void _akhiriLiveStreaming(String uid) async {
    await FirebaseFirestore.instance.collection('live_streams').doc(uid).delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Nusopa LIVE 🎥'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // BANNER UTAMA LIVE STREAMING STYLE SHOPEE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade700,
            child: const Row(
              children: [
                Icon(Icons.live_tv, color: Colors.white, size: 30),
                SizedBox(width: 12),
                Text(
                  'Tonton Seller Live & Ambil Diskon COD!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),

          // DAFTAR TOKO YANG SEDANG LIVE (REALTIME DARI FIRESTORE)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('live_streams')
                  .where('status', isEqualTo: 'streaming')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var liveDocs = snapshot.data!.docs;

                if (liveDocs.isEmpty) {
                  return const Center(
                    child: Text('Saat ini belum ada seller yang melakukan siaran live.', style: TextStyle(color: Colors.grey)),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: liveDocs.length,
                  itemBuilder: (context, index) {
                    var data = liveDocs[index].data() as Map<String, dynamic>;
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(
                          image: NetworkImage('https://unsplash.com'), // Placeholder visual kamera
                          fit: BoxFit.cover,
                          opacity: 0.6,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.between,
                          children: [
                            // Badge LIVE Merah Berkedip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                              child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            // Nama Toko Seller di bagian bawah
                            Text(
                              data['nama_toko'] ?? 'Toko Mitra',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // PANEL ACTION TOMBOL KHUSUS SELLER UNTUK MULAI LIVE
          if (user != null)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, userSnap) {
                if (userSnap.hasData && userSnap.data!.exists) {
                  var uData = userSnap.data!.data() as Map<String, dynamic>;
                  if (uData['role'] == 'seller') {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _akhiriLiveStreaming(user.uid),
                              child: const Text('AKHIRI LIVE'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              icon: const Icon(Icons.videocam),
                              label: const Text('MULAI SHOPEE LIVE'),
                              onPressed: () => _mulaiLiveStreaming(context, user.uid, uData['nama'] ?? 'Toko Saya'),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }
                return const SizedBox.shrink(); // Sembunyikan panel jika dia pembeli biasa
              },
            ),
        ],
      ),
    );
  }
}
