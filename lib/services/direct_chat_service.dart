import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DirectChatService {
  DirectChatService._();
  static final instance = DirectChatService._();
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final storage = FirebaseStorage.instance;
  String get uid => auth.currentUser?.uid ?? (throw StateError('Sesi berakhir.'));

  Stream<QuerySnapshot<Map<String,dynamic>>> inbox() => db.collection('direct_chats').where('participants', arrayContains: uid).snapshots();
  Stream<QuerySnapshot<Map<String,dynamic>>> messages(String chatId) => db.collection('direct_chats').doc(chatId).collection('messages').orderBy('createdAt').snapshots();
  Future<DocumentSnapshot<Map<String,dynamic>>> profile(String id) => db.collection('users').doc(id).get();

  Future<String> getOrCreateChat(String otherUid) async {
    if (otherUid.isEmpty || otherUid == uid) throw ArgumentError('Penerima tidak valid.');
    final q = await db.collection('direct_chats').where('participants', arrayContains: uid).get();
    for (final d in q.docs) { if (List<String>.from(d.data()['participants'] ?? []).contains(otherUid)) return d.id; }
    final ids = [uid, otherUid]..sort();
    final id = '${ids[0]}_${ids[1]}';
    final ref = db.collection('direct_chats').doc(id);
    await db.runTransaction((tx) async {
      if ((await tx.get(ref)).exists) return;
      tx.set(ref, {'participants': ids, 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(), 'lastMessage': '', 'lastMessageType': 'text', 'lastSenderId': uid, 'unreadCounts': {uid: 0, otherUid: 0}});
    });
    return id;
  }

  Future<void> markRead(String chatId) async {
    final ref = db.collection('direct_chats').doc(chatId);
    final d = await ref.get();
    if (!d.exists) return;
    final p = List<String>.from(d.data()?['participants'] ?? []);
    if (!p.contains(uid)) return;
    final c = Map<String,dynamic>.from(d.data()?['unreadCounts'] ?? {}); c[uid] = 0;
    await ref.update({'unreadCounts': c});
  }

  Future<void> sendText(String chatId, String text) async { final v=text.trim(); if(v.isEmpty)return; await _send(chatId, {'type':'text','text':v,'imageUrl':null}, v); }

  Future<void> sendImage(String chatId, File file) async {
    final ref = storage.ref('direct_chats/$chatId/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploaded = await ref.putFile(file, SettableMetadata(contentType:'image/jpeg'));
    final url = await uploaded.ref.getDownloadURL();
    await _send(chatId, {'type':'image','text':'','imageUrl':url}, '📷 Foto');
  }

  Future<void> _send(String chatId, Map<String,dynamic> data, String preview) async {
    final chat = db.collection('direct_chats').doc(chatId);
    final snap = await chat.get();
    if(!snap.exists) throw StateError('Percakapan tidak ditemukan.');
    final p=List<String>.from(snap.data()?['participants'] ?? []);
    if(!p.contains(uid)) throw StateError('Anda bukan peserta.');
    final counts=Map<String,dynamic>.from(snap.data()?['unreadCounts'] ?? {});
    for(final x in p){counts.putIfAbsent(x,()=>0);if(x!=uid)counts[x]=(counts[x] as num).toInt()+1;}
    final batch=db.batch();
    batch.set(chat.collection('messages').doc(), {...data,'senderId':uid,'createdAt':FieldValue.serverTimestamp()});
    batch.update(chat, {'lastMessage':preview,'lastMessageType':data['type'],'lastSenderId':uid,'updatedAt':FieldValue.serverTimestamp(),'unreadCounts':counts});
    await batch.commit();
  }
}
