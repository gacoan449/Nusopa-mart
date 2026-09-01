import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Data layer sosial Nusopa.
/// Feed, interaksi dan moderasi tetap di Firestore agar ringan untuk fase uji.
class SocialService {
  SocialService._();
  static final instance = SocialService._();
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  String get uid => auth.currentUser?.uid ?? '';

  Stream<DocumentSnapshot<Map<String, dynamic>>> myProfile() => db.collection('social_profiles').doc(uid).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> feed() => db
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots();

  Future<String> createPost({
    required String text,
    List<String> imageUrls = const [],
    String? productId,
    String? productName,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw StateError('Sesi pengguna berakhir.');
    final body = text.trim();
    if (body.isEmpty && imageUrls.isEmpty) throw ArgumentError('Postingan tidak boleh kosong.');
    if (imageUrls.length > 10) throw ArgumentError('Maksimal 10 foto per postingan.');

    final profile = await db.collection('social_profiles').doc(user.uid).get();
    final data = profile.data() ?? {};
    final ref = db.collection('posts').doc();
    await ref.set({
      'authorId': user.uid,
      'authorName': (data['displayName'] ?? user.displayName ?? '').toString(),
      'authorPhotoUrl': (data['photoUrl'] ?? user.photoURL ?? '').toString(),
      'text': body,
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
    final batch = db.batch();
    final exists = (await like.get()).exists;
    if (exists) {
      batch.delete(like);
      batch.update(post, {'likeCount': FieldValue.increment(-1)});
    } else {
      batch.set(like, {'userId': uid, 'createdAt': FieldValue.serverTimestamp()});
      batch.update(post, {'likeCount': FieldValue.increment(1)});
    }
    await batch.commit();
    if (!exists && authorId != uid) {
      await _notification(authorId, 'like', postId, 'menyukai postingan Anda.');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> comments(String postId) => db
      .collection('posts').doc(postId).collection('comments')
      .orderBy('createdAt')
      .limit(100)
      .snapshots();

  Future<void> addComment(String postId, {required String authorId, required String text}) async {
    final body = text.trim();
    if (body.isEmpty || uid.isEmpty) return;
    if (body.length > 2000) throw ArgumentError('Komentar terlalu panjang.');
    final profile = await db.collection('social_profiles').doc(uid).get();
    final data = profile.data() ?? {};
    final post = db.collection('posts').doc(postId);
    final comment = post.collection('comments').doc();
    final batch = db.batch();
    batch.set(comment, {
      'authorId': uid,
      'authorName': (data['displayName'] ?? auth.currentUser?.displayName ?? '').toString(),
      'authorPhotoUrl': (data['photoUrl'] ?? auth.currentUser?.photoURL ?? '').toString(),
      'text': body,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(post, {'commentCount': FieldValue.increment(1)});
    await batch.commit();
    if (authorId != uid) await _notification(authorId, 'comment', postId, 'mengomentari postingan Anda.');
  }

  /// Records one share per user and creates a real repost in the feed.
  /// Repeated taps do not inflate the counter or create duplicate reposts.
  Future<void> sharePost(String postId, {required String authorId}) async {
    if (uid.isEmpty) return;
    final originalRef = db.collection('posts').doc(postId);
    final shareRef = originalRef.collection('shares').doc(uid);
    final repostRef = db.collection('posts').doc('${postId}_repost_$uid');
    final original = await originalRef.get();
    if (!original.exists) throw StateError('Postingan sudah tidak tersedia.');
    final data = original.data()!;
    final existing = await shareRef.get();
    if (existing.exists) return;

    final profile = await db.collection('social_profiles').doc(uid).get();
    final me = profile.data() ?? {};
    final batch = db.batch();
    batch.set(shareRef, {'userId': uid, 'createdAt': FieldValue.serverTimestamp()});
    batch.update(originalRef, {'shareCount': FieldValue.increment(1)});
    batch.set(repostRef, {
      'authorId': uid,
      'authorName': (me['displayName'] ?? auth.currentUser?.displayName ?? '').toString(),
      'authorPhotoUrl': (me['photoUrl'] ?? auth.currentUser?.photoURL ?? '').toString(),
      'text': '',
      'imageUrls': const [],
      'productId': null,
      'productName': null,
      'likeCount': 0,
      'commentCount': 0,
      'shareCount': 0,
      'repostOf': postId,
      'originalAuthorId': data['authorId'],
      'originalAuthorName': data['authorName'],
      'originalText': data['text'],
      'originalImageUrls': data['imageUrls'] ?? const [],
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    if (authorId != uid) await _notification(authorId, 'share', postId, 'membagikan postingan Anda.');
  }

  Future<void> reportPost(String postId, {required String reason, String? details}) async {
    if (uid.isEmpty) return;
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) throw ArgumentError('Alasan laporan wajib diisi.');
    await db.collection('post_reports').add({
      'postId': postId,
      'reporterId': uid,
      'reason': cleanReason,
      'details': (details ?? '').trim(),
      'status': 'OPEN',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> isFollowing(String targetId) async => (await db.collection('social_profiles').doc(targetId).collection('followers').doc(uid).get()).exists;

  Future<void> toggleFollow(String targetId) async {
    if (uid.isEmpty || targetId == uid) return;
    final follower = db.collection('social_profiles').doc(targetId).collection('followers').doc(uid);
    final following = db.collection('social_profiles').doc(uid).collection('following').doc(targetId);
    final exists = (await follower.get()).exists;
    final batch = db.batch();
    if (exists) {
      batch.delete(follower);
      batch.delete(following);
    } else {
      batch.set(follower, {'userId': uid, 'createdAt': FieldValue.serverTimestamp()});
      batch.set(following, {'userId': targetId, 'createdAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
    if (!exists) await _notification(targetId, 'follow', uid, 'mulai mengikuti Anda.');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> notifications() => db
      .collection('notifications').where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true).limit(50).snapshots();

  Future<void> markNotificationRead(String id) => db.collection('notifications').doc(id).update({'read': true});

  Future<void> _notification(String targetId, String type, String referenceId, String message) async {
    final me = await db.collection('social_profiles').doc(uid).get();
    final name = (me.data()?['displayName'] ?? auth.currentUser?.email ?? 'Pengguna').toString();
    await db.collection('notifications').add({
      'userId': targetId,
      'actorId': uid,
      'actorName': name,
      'type': type,
      'referenceId': referenceId,
      'message': message,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String conversationId(String otherUid) => ([uid, otherUid]..sort()).join('_');
}
