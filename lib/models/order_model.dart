class OrderModel {
  final String orderId;
  final String buyerId;       // Relasi ke akun pembeli
  final String sellerId;      // Relasi ke toko penjual
  final String productName;
  final String productImage;
  final int price;
  final int qty;              // Jumlah barang yang dibeli
  final int ongkirManual;     // Ongkir yang ditetapkan admin/seller
  final String status;
  
  // Data Logistik (Dibuat Nullable '?' karena resi belum ada saat pesanan baru dibuat)
  final String? namaEkspedisi;
  final String? nomorResi;
  final String? fotoResiUrl;
  final String? linkCekLogistik;

  const OrderModel({
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.productName,
    required this.productImage,
    required this.price,
    this.qty = 1,
    this.ongkirManual = 0,
    required this.status,
    this.namaEkspedisi,
    this.nomorResi,
    this.fotoResiUrl,
    this.linkCekLogistik,
  });

  // Fungsi khusus Firebase: Mengubah format Map dari Firestore menjadi Objek Dart
  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    return OrderModel(
      orderId: documentId,
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      productName: map['productName'] ?? 'Produk Tidak Diketahui',
      productImage: map['productImage'] ?? '',
      price: map['price']?.toInt() ?? 0,
      qty: map['qty']?.toInt() ?? 1,
      ongkirManual: map['ongkirManual']?.toInt() ?? 0,
      status: map['status'] ?? 'Menunggu Pembayaran',
      namaEkspedisi: map['namaEkspedisi'],
      nomorResi: map['nomorResi'],
      fotoResiUrl: map['fotoResiUrl'],
      linkCekLogistik: map['linkCekLogistik'],
    );
  }

  // Fungsi khusus Firebase: Mengubah Objek Dart menjadi Map untuk disimpan ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'sellerId': sellerId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'qty': qty,
      'ongkirManual': ongkirManual,
      'status': status,
      'namaEkspedisi': namaEkspedisi,
      'nomorResi': nomorResi,
      'fotoResiUrl': fotoResiUrl,
      'linkCekLogistik': linkCekLogistik,
    };
  }
}
