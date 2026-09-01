import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Data layer fitur sosial Nusopa.Mart.
/// Semua konten berasal dari Firestore; tidak ada seed/dummy post di UI.
class SocialService {
  SocialService._();
  static final instance = SocialService._();

  final FirebaseFirestore db = FirebaseFirestore.instance;
  FirebaseAuth get auth => FirebaseAuth.instance;
  String get uid => auth.currentUser?.uid ?? '';

  Stream<DocumentSnapshot<Map<String, dynamic>>> myProfile() => db.collection('users').doc(uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> feed() => db.collection('posts').orderBy('createdAt', descending: true).limit(50).snapshots();

  Future<String> createPost({required String text, List<String> imageUrls = const [], String? productId, String? productName}) async {
    final user = auth.currentUser;
    if (user == null) throw StateError('Sesi pengguna berakhir.');
    final ref = db.collection('posts').doc();
    final profile = await db.collection('users').doc(user.uid).get();
    final data = profile.data() ?? {};
    await ref.set({
      'authorId': user.uid,
      'authorName': (data['displayName'] ?? user.displayName ?? '').toString(),
      'authorPhotoUrl': (data['photoUrl'] ?? user.photoURL ?? '').toString(),
      'text': text.trim(),
      'imageUrls': imageUrls,
      'productId': productId,
      'productName': productName,
      'likeCount': 0,
      'commentCount': 0,
      'shareCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<bool> liked(String postId) => db.collection('posts').doc(postId).collection('likes').doc(uid).snapshots().map((d) => d.exists);

  Future<void> toggleLike(String postId, {required String authorId}) async {
    if (uid.isEmpty) return;
    final post = db.collection('posts').doc(postId);
    final like = post.collection('likes').doc(uid);
    final exists = (await like.get()).exists;
    final batch = db.batch();
    if (exists) {
      batch.delete(like);
      batch.update(post, {'likeCount': FieldValue.increment(-1)});
    } else {
      batch.set(like, {'userId': uid, 'createdAt': FieldValue.serverTimestamp()});
      batch.update(post, {'likeCount': FieldValue.increment(1)});
      if (authorId != uid) await _notification(authorId, 'like', postId, 'menyukai postingan Anda.');
    }
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> comments(String postId) => db.collection('posts').doc(postId).collection('comments').orderBy('createdAt').snapshots();

  Future<void> addComment(String postId, {required String authorId, required String text}) async {
    final body = text.trim();
    if (body.isEmpty || uid.isEmpty) return;
    final profile = await db.collection('users').doc(uid).get();
    final data = profile.data() ?? {};
    final post = db.collection('posts').doc(postId);
    await post.collection('comments').add({
      'authorId': uid,
      'authorName': (data['displayName'] ?? '').toString(),
      'authorPhotoUrl': (data['photoUrl'] ?? '').toString(),
      'text': body,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await post.update({'commentCount': FieldValue.increment(1)});
    if (authorId != uid) await _notification(authorId, 'comment', postId, 'mengomentari postingan Anda.');
  }

  Future<void> sharePost(String postId, {required String authorId}) async {
    await db.collection('posts').doc(postId).update({'shareCount': FieldValue.increment(1)});
    if (authorId != uid) await _notification(authorId, 'share', postId, 'membagikan postingan Anda.');
  }

  Future<bool> isFollowing(String targetId) async => (await db.collection('users').doc(targetId).collection('followers').doc(uid).get()).exists;

  Future<void> toggleFollow(String targetId) async {
    if (uid.isEmpty || targetId == uid) return;
    final follower = db.collection('users').doc(targetId).collection('followers').doc(uid);
    final following = db.collection('users').doc(uid).collection('following').doc(targetId);
    final exists = (await follower.get()).exists;
    final batch = db.batch();
    if (exists) {
      batch.delete(follower);
      batch.delete(following);
    } else {
      batch.set(follower, {'userId': uid, 'createdAt': FieldValue.serverTimestamp()});
      batch.set(following, {'userId': targetId, 'createdAt': FieldValue.serverTimestamp()});
      await _notification(targetId, 'follow', uid, 'mulai mengikuti Anda.');
    }
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> notifications() => db.collection('notifications').where('userId', isEqualTo: uid).orderBy('createdAt', descending: true).limit(50).snapshots();

  Future<void> markNotificationRead(String id) => db.collection('notifications').doc(id).update({'read': true});

  Future<void> _notification(String targetId, String type, String referenceId, String message) async {
    final me = await db.collection('users').doc(uid).get();
    final name = (me.data()?['displayName'] ?? auth.currentUser?.email ?? 'Pengguna').toString();
    await db.collection('notifications').add({'userId': targetId, 'actorId': uid, 'actorName': name, 'type': type, 'referenceId': referenceId, 'message': message, 'read': false, 'createdAt': FieldValue.serverTimestamp()});
  }

  String conversationId(String otherUid) => ([uid, otherUid]..sort()).join('_');
}
