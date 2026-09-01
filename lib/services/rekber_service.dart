import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Rekber data layer.
///
/// Nusopa does not move customer money through an API/wallet inside the app.
/// Funds are held/settled by the prepared institutional account. Firestore
/// stores order, payment-proof and operational state; only authorized admins
/// may verify external settlement and complete the escrow workflow.
class RekberService {
  RekberService._();
  static final instance = RekberService._();

  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  String get uid {
    final value = auth.currentUser?.uid;
    if (value == null || value.isEmpty) {
      throw StateError('Sesi pengguna berakhir. Silakan masuk kembali.');
    }
    return value;
  }

  static const int adminFee = 3000;

  Stream<QuerySnapshot<Map<String, dynamic>>> buyerOrders() => db
      .collection('orders')
      .where('buyerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> sellerOrders() => db
      .collection('orders')
      .where('sellerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots();

  Future<String> createOrder({
    required String sellerId,
    required String productId,
    required String productName,
    required int price,
    required int qty,
    required int shippingCost,
  }) async {
    if (sellerId.isEmpty || productId.isEmpty) {
      throw ArgumentError('Penjual dan produk wajib diisi.');
    }
    if (sellerId == uid) {
      throw ArgumentError('Anda tidak dapat membeli produk sendiri.');
    }
    if (price < 0 || qty <= 0 || shippingCost < 0) {
      throw ArgumentError('Harga, jumlah, atau ongkir tidak valid.');
    }

    final subtotal = price * qty;
    final total = subtotal + shippingCost + adminFee;
    final ref = db.collection('orders').doc();
    await ref.set({
      'buyerId': uid,
      'sellerId': sellerId,
      'productId': productId,
      'productName': productName.trim(),
      'price': price,
      'qty': qty,
      'subtotal': subtotal,
      'shippingCost': shippingCost,
      'adminFee': adminFee,
      'total': total,
      'status': 'MENUNGGU_PEMBAYARAN',
      'paymentStatus': 'UNPAID',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Buyer submits proof for the external institutional transfer. This never
  /// means the money has been verified; an authorized admin must verify it.
  Future<void> submitPayment({
    required String orderId,
    required String proofUrl,
  }) async {
    if (orderId.isEmpty || proofUrl.trim().isEmpty) {
      throw ArgumentError('Order dan bukti pembayaran wajib diisi.');
    }

    final orderRef = db.collection('orders').doc(orderId);
    final paymentRef = db.collection('payments').doc();
    final snapshot = await orderRef.get();
    if (!snapshot.exists) throw StateError('Pesanan tidak ditemukan.');
    final order = snapshot.data()!;

    if (order['buyerId'] != uid) throw StateError('Pesanan bukan milik Anda.');
    if (order['status'] != 'MENUNGGU_PEMBAYARAN' ||
        order['paymentStatus'] != 'UNPAID') {
      throw StateError('Pesanan tidak sedang menunggu pembayaran.');
    }

    final batch = db.batch();
    batch.set(paymentRef, {
      'orderId': orderId,
      'buyerId': uid,
      'amount': order['total'],
      'proofUrl': proofUrl.trim(),
      'status': 'MENUNGGU_VERIFIKASI',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(orderRef, {
      'paymentStatus': 'MENUNGGU_VERIFIKASI',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> submitShipping({
    required String orderId,
    required String courier,
    required String trackingNumber,
    required int shippingCost,
  }) async {
    if (orderId.isEmpty || courier.trim().isEmpty || trackingNumber.trim().isEmpty) {
      throw ArgumentError('Kurir dan nomor resi wajib diisi.');
    }
    if (shippingCost < 0) throw ArgumentError('Ongkir tidak valid.');

    final ref = db.collection('orders').doc(orderId);
    final snapshot = await ref.get();
    if (!snapshot.exists) throw StateError('Pesanan tidak ditemukan.');
    final order = snapshot.data()!;
    if (order['sellerId'] != uid) throw StateError('Pesanan bukan milik toko Anda.');
    if (!const ['DIPROSES', 'SIAP_DIKIRIM'].contains(order['status'])) {
      throw StateError('Pesanan belum dapat dikirim.');
    }

    await ref.update({
      'courier': courier.trim(),
      'trackingNumber': trackingNumber.trim(),
      'shippingCost': shippingCost,
      'status': 'DIKIRIM',
      'shippedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> confirmReceived(String orderId) async {
    final ref = db.collection('orders').doc(orderId);
    final snapshot = await ref.get();
    if (!snapshot.exists) throw StateError('Pesanan tidak ditemukan.');
    final order = snapshot.data()!;
    if (order['buyerId'] != uid) throw StateError('Pesanan bukan milik Anda.');
    if (order['status'] != 'DIKIRIM') {
      throw StateError('Pesanan belum berstatus dikirim.');
    }

    await ref.update({
      'status': 'DITERIMA',
      'receivedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> requestWithdrawal({
    required int amount,
    required String bank,
    required String accountNumber,
    required String accountName,
  }) async {
    if (amount <= 0 || bank.trim().isEmpty || accountNumber.trim().isEmpty || accountName.trim().isEmpty) {
      throw ArgumentError('Data pencairan tidak valid.');
    }
    await db.collection('withdrawals').add({
      'sellerId': uid,
      'amount': amount,
      'bank': bank.trim(),
      'accountNumber': accountNumber.trim(),
      'accountName': accountName.trim(),
      'status': 'MENUNGGU_ADMIN',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelUnpaidOrder(String orderId) async {
    final ref = db.collection('orders').doc(orderId);
    final snapshot = await ref.get();
    if (!snapshot.exists) throw StateError('Pesanan tidak ditemukan.');
    final order = snapshot.data()!;
    if (order['buyerId'] != uid) throw StateError('Pesanan bukan milik Anda.');
    if (order['status'] != 'MENUNGGU_PEMBAYARAN' || order['paymentStatus'] != 'UNPAID') {
      throw StateError('Pesanan sudah masuk proses pembayaran.');
    }
    await ref.update({
      'status': 'DIBATALKAN',
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
