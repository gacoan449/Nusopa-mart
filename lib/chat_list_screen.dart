import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login terlebih dahulu.', style: TextStyle(color: Colors.grey))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Kotak Masuk Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.orange.shade800, // Tema Selaras Khas COD Nusopa
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('users', arrayContains: user.uid)
            .orderBy('last_update', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // PERBAIKAN 2: Proteksi penanganan error / link pembuatan composite index Firebase
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Terjadi kendala data. Pastikan Composite Index Firestore sudah dibuat. Eror: ${snapshot.error}', 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(fontSize: 12, color: Colors.red)
                ),
              ),
            );
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          var rooms = snapshot.data!.docs;

          if (rooms.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Belum ada riwayat obrolan pesan.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              var roomData = rooms[index].data() as Map<String, dynamic>;
              String roomId = rooms[index].id;
              String lastMsg = roomData['last_message'] ?? 'Mengirim tautan/pesan';
              
              // PERBAIKAN 1 (Rekomendasi Utama): Membaca nama langsung dari dokumen chat_rooms (Denormalisasi)
              // Saat membuat room chat baru di database, pastikan Anda juga menyimpan map data:
              // 'nama_pengguna': { 'uid_pembeli': 'Nama Pembeli', 'uid_seller': 'Nama Toko Seller' }
              String namaLawan = "Pengguna Nusopa";
              if (roomData['nama_pengguna'] != null) {
                var mapNama = roomData['nama_pengguna'] as Map<String, dynamic>;
                // Cari nama yang key-nya bukan milik user aktif saat ini
                String? keyLawan = mapNama.keys.firstWhere((key) => key != user.uid, orElse: () => '');
                if (keyLawan.isNotEmpty) {
                  namaLawan = mapNama[keyLawan] ?? "Pengguna Nusopa";
                }
              } else {
                // Cadangan Lama (Hanya dijalankan jika data lama belum di-update map nama-nya)
                List usersInRoom = roomData['users'] ?? [];
                namaLawan = usersInRoom.firstWhere((id) => id != user.uid, orElse: () => 'Mitra Nusopa');
              }

              // Format visual tanggal pesan terakhir (opsional jika ada field 'last_update')
              String waktuTeks = "";
              if (roomData['last_update'] != null) {
                Timestamp ts = roomData['last_update'];
                DateTime dt = ts.toDate();
                waktuTeks = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
              }

              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: Colors.grey.shade200)
                ),
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.orange.shade50,
                    child: Icon(Icons.person, color: Colors.orange.shade800, size: 22),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      Expanded(
                        child: Text(
                          namaLawan, 
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                        ),
                      ),
                      Text(waktuTeks, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      lastMsg, 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, size: 14, color: Colors.grey.shade400),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(
                          chatRoomId: roomId,
                          namaLawanBicara: namaLawan,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
