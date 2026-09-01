import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestore data layer. Financial state must only be mutated by trusted admin/server rules.
class RekberService {
  RekberService._();
  static final instance = RekberService._();
  final db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  static const int adminFee = 3000;

  Stream<QuerySnapshot<Map<String, dynamic>>> buyerOrders() => db.collection('orders').where('buyerId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> sellerOrders() => db.collection('orders').where('sellerId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots();

  Future<String> createOrder({required String sellerId, required String productId, required String productName, required int price, required int qty, required int shippingCost}) async {
    final subtotal = price * qty;
    final total = subtotal + shippingCost + adminFee;
    final ref = db.collection('orders').doc();
    await ref.set({'buyerId': uid,'sellerId': sellerId,'productId': productId,'productName': productName,'price': price,'qty': qty,'subtotal': subtotal,'shippingCost': shippingCost,'adminFee': adminFee,'total': total,'status':'MENUNGGU_PEMBAYARAN','paymentStatus':'UNPAID','createdAt':FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> submitPayment({required String orderId, required String proofUrl}) async {
    final ref = db.collection('payments').doc();
    await ref.set({'orderId':orderId,'buyerId':uid,'proofUrl':proofUrl,'status':'MENUNGGU_VERIFIKASI','createdAt':FieldValue.serverTimestamp()});
  }

  Future<void> submitShipping({required String orderId, required String courier, required String trackingNumber, required int shippingCost}) => db.collection('orders').doc(orderId).update({'courier':courier,'trackingNumber':trackingNumber,'shippingCost':shippingCost,'status':'DIKIRIM','shippedAt':FieldValue.serverTimestamp()});

  Future<void> confirmReceived(String orderId) => db.collection('orders').doc(orderId).update({'status':'DITERIMA','receivedAt':FieldValue.serverTimestamp()});

  Future<void> requestWithdrawal({required int amount, required String bank, required String accountNumber, required String accountName}) => db.collection('withdrawals').add({'sellerId':uid,'amount':amount,'bank':bank,'accountNumber':accountNumber,'accountName':accountName,'status':'MENUNGGU_ADMIN','createdAt':FieldValue.serverTimestamp()});
}
