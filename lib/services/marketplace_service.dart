import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarketplaceService {
  final _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  static const fee = 3000;

  Future<String> createOrder({required String sellerId, required String productName, required int productPrice, int shippingCost = 0}) async {
    final total = productPrice + shippingCost + fee;
    final ref = await _db.collection('orders').add({
      'buyerId': uid, 'sellerId': sellerId, 'productName': productName,
      'productPrice': productPrice, 'shippingCost': shippingCost,
      'escrowFee': fee, 'total': total, 'status': 'MENUNGGU_PEMBAYARAN',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> submitPayment({required String orderId, required String proofUrl}) =>
    _db.collection('payments').add({'orderId': orderId,'buyerId': uid,'proofUrl': proofUrl,'status':'MENUNGGU_VERIFIKASI','createdAt':FieldValue.serverTimestamp()});

  Future<void> addShipping({required String orderId, required String courier, required String trackingNumber, required int shippingCost}) =>
    _db.collection('orders').doc(orderId).update({'courier':courier,'trackingNumber':trackingNumber,'shippingCost':shippingCost,'status':'DIKIRIM','shippedAt':FieldValue.serverTimestamp()});

  Future<void> requestWithdrawal({required int amount, required String bank, required String accountNumber, required String accountName}) =>
    _db.collection('withdrawals').add({'sellerId':uid,'amount':amount,'bank':bank,'accountNumber':accountNumber,'accountName':accountName,'status':'MENUNGGU_ADMIN','createdAt':FieldValue.serverTimestamp()});
}
