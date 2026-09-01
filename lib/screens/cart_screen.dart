import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/cart_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  static const blue = Color(0xFF126BFF);

  int _int(dynamic value) => value is int ? value : int.tryParse(value.toString()) ?? 0;

  String _money(int value) =>
      'Rp${value.toString().replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (_) => '.')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text('Keranjang', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: CartService.instance.watch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Keranjang tidak dapat dimuat: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) return _empty();

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
            children: [
              ...docs.map((doc) => _row(context, doc)),
              const Card(
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Harga dan stok diverifikasi kembali saat checkout. '
                    'Biaya Rekber Rp3.000 dikenakan per order.',
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: CartService.instance.watch(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) return const SizedBox.shrink();
          final items = docs.map((doc) {
            return <String, dynamic>{...doc.data(), 'cartId': doc.id};
          }).toList();

          return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.black12)),
              ),
              child: FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CheckoutScreen.cart(items: items)),
                ),
                child: const Text('CHECKOUT SEMUA'),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Keranjang masih kosong',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text('Pilih produk untuk mulai transaksi Rekber.'),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').doc(doc.id).snapshots(),
      builder: (context, snapshot) {
        final product = snapshot.data?.data() ?? <String, dynamic>{};
        final name = (product['name'] ?? product['productName'] ?? 'Produk tidak tersedia').toString();
        final image = (product['imageUrl'] ?? product['image'] ?? '').toString();
        final price = _int(product['price'] ?? product['productPrice']);
        final stock = _int(product['stock']);
        final qty = _int(doc.data()['qty']).clamp(1, 999);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: SizedBox(
                    width: 78,
                    height: 78,
                    child: image.isEmpty
                        ? Container(
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.image_outlined),
                          )
                        : Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _money(price),
                        style: const TextStyle(color: blue, fontWeight: FontWeight.w800),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: qty > 1
                                ? () => CartService.instance.setQuantity(doc.id, qty - 1)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline, size: 21),
                          ),
                          Text('$qty'),
                          IconButton(
                            onPressed: stock > qty
                                ? () => CartService.instance.setQuantity(doc.id, qty + 1)
                                : null,
                            icon: const Icon(Icons.add_circle_outline, size: 21),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => CartService.instance.remove(doc.id),
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
