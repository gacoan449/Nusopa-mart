import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Silakan login.')));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Kotak Masuk Chat'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Membaca room chat yang di dalamnya ada UID milik pengguna aktif saat ini
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('users', arrayContains: user.uid)
            .orderBy('last_update', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var rooms = snapshot.data!.docs;

          if (rooms.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 50, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('Belum ada riwayat obrolan pesan.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              var roomData = rooms[index].data() as Map<String, dynamic>;
              String roomId = rooms[index].id;
              String lastMsg = roomData['last_message'] ?? '';

              // Mencari UID milik lawan bicara di dalam array [pembeli, penjual]
              List usersInRoom = roomData['users'] ?? [];
              String lawanUid = usersInRoom.firstWhere((id) => id != user.uid, orElse: () => '');

              // Tarik nama profil lawan bicara berdasarkan Uid-nya dari tabel 'users'
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(lawanUid).get(),
                builder: (context, userSnapshot) {
                  String namaLawan = "Pengguna Nusopa";
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    var d = userSnapshot.data!.data() as Map<String, dynamic>;
                    namaLawan = d['nama'] ?? "Pengguna Nusopa";
                  }

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(Icons.person, color: Colors.blue.shade700),
                      ),
                      title: Text(namaLawan, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.chevron_right, size: 16),
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
          );
        },
      ),
    );
  }
}
