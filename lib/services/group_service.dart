import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupService {
  GroupService._();
  static final instance=GroupService._();
  final db=FirebaseFirestore.instance;
  String get uid=>FirebaseAuth.instance.currentUser?.uid??'';
  Stream<QuerySnapshot<Map<String,dynamic>>> groups()=>db.collection('groups').orderBy('createdAt',descending:true).limit(50).snapshots();
  Stream<QuerySnapshot<Map<String,dynamic>>> members(String groupId)=>db.collection('groups').doc(groupId).collection('members').snapshots();
  Stream<QuerySnapshot<Map<String,dynamic>>> discussions(String groupId)=>db.collection('groups').doc(groupId).collection('posts').orderBy('createdAt',descending:true).limit(50).snapshots();
  Stream<QuerySnapshot<Map<String,dynamic>>> messages(String groupId)=>db.collection('groups').doc(groupId).collection('messages').orderBy('createdAt',descending:false).limitToLast(100).snapshots();
  Future<bool> isMember(String groupId)async=>(await db.collection('groups').doc(groupId).collection('members').doc(uid).get()).exists;
  Future<void> join(String groupId)async{if(uid.isEmpty)return;final ref=db.collection('groups').doc(groupId).collection('members').doc(uid);if((await ref.get()).exists){await ref.delete();}else{await ref.set({'userId':uid,'joinedAt':FieldValue.serverTimestamp()});}}
  Future<String> createDiscussion(String groupId,String text)async{final user=FirebaseAuth.instance.currentUser;if(user==null||text.trim().isEmpty)throw StateError('Sesi pengguna berakhir.');final p=(await db.collection('social_profiles').doc(user.uid).get()).data()??{};final ref=db.collection('groups').doc(groupId).collection('posts').doc();await ref.set({'authorId':user.uid,'authorName':(p['displayName']??user.email??'Pengguna').toString(),'authorPhotoUrl':(p['photoUrl']??'').toString(),'text':text.trim(),'likeCount':0,'commentCount':0,'createdAt':FieldValue.serverTimestamp()});return ref.id;}
  Future<void> sendText(String groupId,String text)async{if(uid.isEmpty||text.trim().isEmpty)return;await db.collection('groups').doc(groupId).collection('messages').add({'senderId':uid,'type':'text','text':text.trim(),'readBy':[uid],'createdAt':FieldValue.serverTimestamp()});}
  Future<void> sendImage(String groupId,String imageUrl)async{if(uid.isEmpty||imageUrl.trim().isEmpty)return;await db.collection('groups').doc(groupId).collection('messages').add({'senderId':uid,'type':'image','text':'','imageUrl':imageUrl.trim(),'readBy':[uid],'createdAt':FieldValue.serverTimestamp()});}
  Future<void> sendProduct(String groupId,{required String productId,required String productName,required String imageUrl,required int price})async{if(uid.isEmpty)return;await db.collection('groups').doc(groupId).collection('messages').add({'senderId':uid,'type':'product','text':productName.trim(),'productId':productId,'productName':productName.trim(),'imageUrl':imageUrl.trim(),'price':price,'readBy':[uid],'createdAt':FieldValue.serverTimestamp()});}
  Future<void> markRead(String groupId,String messageId,List<dynamic> readBy)async{if(uid.isEmpty||readBy.contains(uid))return;await db.collection('groups').doc(groupId).collection('messages').doc(messageId).update({'readBy':FieldValue.arrayUnion([uid])});}
  Future<void> likeDiscussion(String groupId,String postId)async{if(uid.isEmpty)return;final post=db.collection('groups').doc(groupId).collection('posts').doc(postId);final like=post.collection('likes').doc(uid);final exists=(await like.get()).exists;final batch=db.batch();if(exists){batch.delete(like);batch.update(post,{'likeCount':FieldValue.increment(-1)});}else{batch.set(like,{'userId':uid,'createdAt':FieldValue.serverTimestamp()});batch.update(post,{'likeCount':FieldValue.increment(1)});}await batch.commit();}
  Future<String> createGroup({required String name,required String privacy})async{final user=FirebaseAuth.instance.currentUser;if(user==null||name.trim().isEmpty)throw StateError('Sesi pengguna berakhir.');final ref=db.collection('groups').doc();await ref.set({'name':name.trim(),'privacy':privacy,'ownerId':user.uid,'createdAt':FieldValue.serverTimestamp()});await ref.collection('members').doc(user.uid).set({'userId':user.uid,'joinedAt':FieldValue.serverTimestamp(),'role':'owner'});return ref.id;}
}
