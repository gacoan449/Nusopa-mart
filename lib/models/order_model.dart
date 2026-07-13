class OrderModel {
  final String orderId;
  final String productName;
  final String productImage;
  final int price;
  final String status;
  final String namaEkspedisi;
  final String nomorResi;
  final String fotoResiUrl;
  final String linkCekLogistik;

  const OrderModel({
    required this.orderId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.status,
    required this.namaEkspedisi,
    required this.nomorResi,
    required this.fotoResiUrl,
    required this.linkCekLogistik,
  });
}
