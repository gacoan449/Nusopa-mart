class OrderModel {
  final String orderId;
  final String productName;
  final String productImage;
  final double price;
  final String status; // 'DIKEMAS', 'DIKIRIM', 'SELESAI'
  
  // Fitur Logistik Manual Tanpa API Key
  final String? namaEkspedisi;
  final String? nomorResi;
  final String? fotoResiUrl;
  final String? linkCekLogistik; // URL yang nanti dibuka di Chrome

  OrderModel({
    required this.orderId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.status,
    this.namaEkspedisi,
    this.nomorResi,
    this.fotoResiUrl,
    this.linkCekLogistik,
  });
}
