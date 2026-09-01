import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartService {
  CartService._();
  static final instance = CartService._();
  final FirebaseFirestore db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  CollectionReference<Map<String, dynamic>> get _items => db.collection('carts').doc(uid).collection('items');
  Stream<QuerySnapshot<Map<String, dynamic>>> watch() => _items.orderBy('addedAt', descending: true).snapshots();
  Future<void> addProduct({required String productId, required int qty}) async { if (qty < 1) return; await _items.doc(productId).set({'productId': productId, 'qty': qty, 'addedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true)); }
  Future<void> setQuantity(String productId, int qty) async { if (qty <= 0) return remove(productId); await _items.doc(productId).set({'productId': productId, 'qty': qty, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true)); }
  Future<void> remove(String productId) => _items.doc(productId).delete();
  Future<void> clear() async { final snap = await _items.get(); final batch = db.batch(); for (final d in snap.docs) { batch.delete(d.reference); } await batch.commit(); }
}
