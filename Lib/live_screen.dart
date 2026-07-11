import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final User? _userAktif = FirebaseAuth.instance.currentUser;
  bool _apakahSeller = false;
  String _namaTokoSeller = "Toko Mitra";
  bool _sedangMemuatRole = true;

  @override
  void initState() {
    super.initState();
    _cekPeranUserSekaliSaja();
  }

  // PERBAIKAN UTAMA: Ambil data role hanya sekali saat layar dibuka (Menghemat Kuota Firebase)
  void _cekPeranUserSekaliSaja() async {
    if (_userAktif != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userAktif!.uid)
            .get();
        
        if (userDoc.exists) {
          var uData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _apakahSeller = uData['role'] == 'seller';
            _namaTokoSeller = uData['nama'] ?? 'Toko Saya';
          });
        }
      } catch (e) {
        debugPrint("Gagal mengambil data user: $e");
      }
    }
    setState(() {
      _sedangMemuatRole = false;
    });
  }

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
        const SnackBar(content: Text('Siaran Langsung Berhasil Diaktifkan!')),
      );
      
      // DISINI TEMPAT PINDAH HALAMAN KAMERA NYATA (Agora/Zego)
      // Navigator.push(context, MaterialPageRoute(builder: (context) => RoomKameraLive(uid: uid)));
    }
  }

  // SISI SELLER: Fungsi mematikan live streaming
  void _akhiriLiveStreaming(String uid) async {
    await FirebaseFirestore.instance.collection('live_streams').doc(uid).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Siaran langsung telah dihentikan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Nusopa LIVE 🎥'),
        backgroundColor: Colors.orange.shade800, // Disamakan warna oranye premium Shopee COD
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // BANNER UTAMA LIVE STREAMING STYLE SHOPEE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.red.shade700,
            child: const Row(
              children: [
                Icon(Icons.live_tv, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tonton Seller Live & Ambil Diskon COD Terdekat!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // DAFTAR TOKO YANG SEDNG LIVE (REALTIME DARI FIRESTORE)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('live_streams')
                  .where('status', isEqualTo: 'streaming')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Eror: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                var liveDocs = snapshot.data!.docs;

                if (liveDocs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_off, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Belum ada seller yang melakukan siaran live.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: liveDocs.length,
                  itemBuilder: (context, index) {
                    var data = liveDocs[index].data() as Map<String, dynamic>;
                    
                    return GestureDetector(
                      onTap: () {
                        // DISINI TEMPAT PEMBELI MASUK UNTUK NONTON LIVE
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                          image: const DecorationImage(
                            // PERBAIKAN 1: Direct link gambar asli penonton live agar tidak pecah/eror
                            image: NetworkImage('https://unsplash.com'),
                            fit: BoxFit.cover,
                            opacity: 0.5, // Digelapkan sedikit agar teks nama toko terbaca jelas
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.between,
                            children: [
                              // Badge LIVE Merah Bergaya Shopee Asli
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red, 
                                  borderRadius: BorderRadius.circular(4)
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                                    SizedBox(width: 4),
                                    Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              // Nama Toko Seller di bagian bawah dengan shadow pengaman baca
                              Text(
                                data['nama_toko'] ?? 'Toko Mitra',
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 13,
                                  shadows: [Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1))]
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // PANEL ACTION TOMBOL KHUSUS SELLER UNTUK MULAI LIVE
          if (!_sedangMemuatRole && _apakahSeller && _userAktif != null)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4, offset: const Offset(0, -2))]
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _akhiriLiveStreaming(_userAktif!.uid),
                        child: const Text('AKHIRI LIVE', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700, 
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))
