import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> product;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const orange = Color(0xFFFF5722);
  int qty = 1;

  int val(dynamic value) => value is num ? value.toInt() : int.tryParse(value.toString()) ?? 0;

  String money(dynamic value) {
    final number = val(value);
    return 'Rp${number.toString().replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (_) => '.')}';
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final name = (product['name'] ?? product['productName'] ?? 'Produk').toString();
    final image = (product['imageUrl'] ?? product['image'] ?? '').toString();
    final seller = (product['sellerId'] ?? product['ownerId'] ?? '').toString();
    final price = val(product['price'] ?? product['productPrice']);
    final stock = val(product['stock']);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Detail Produk'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: image.isEmpty
                ? Container(
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                  )
                : Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.broken_image_outlined, size: 64),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  money(price),
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: orange),
                ),
                const SizedBox(height: 9),
                Text(
                  '⭐ ${product['rating'] ?? 5.0}   •   Terjual ${product['sold'] ?? 0}',
                  style: GoogleFonts.inter(color: Colors.black54),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Color(0xFF16803A)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Rekber Aman — transaksi mengikuti proses pembayaran, pengiriman dan verifikasi.'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Jumlah', style: TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                      onPressed: qty > 1 ? () => setState(() => qty--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$qty', style: const TextStyle(fontWeight: FontWeight.w800)),
                    IconButton(
                      onPressed: stock > qty ? () => setState(() => qty++) : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                Text(
                  stock > 0 ? 'Stok tersedia: $stock' : 'Stok habis',
                  style: TextStyle(color: stock > 0 ? Colors.black54 : Colors.red),
                ),
                const SizedBox(height: 20),
                Text('Deskripsi', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 7),
                Text(
                  (product['description'] ?? 'Belum ada deskripsi produk.').toString(),
                  style: GoogleFonts.inter(height: 1.55),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.black12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: seller.isEmpty || price <= 0
                      ? null
                      : () async {
                          await CartService.instance.addProduct(productId: widget.productId, qty: qty);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Produk masuk ke keranjang.')),
                            );
                          }
                        },
                  icon: const Icon(Icons.add_shopping_cart_outlined),
                  label: const Text('KERANJANG'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: seller.isEmpty || price <= 0 || stock < qty
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutScreen(
                                sellerId: seller,
                                productId: widget.productId,
                                productName: name,
                                price: price,
                              ),
                            ),
                          ),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('BELI SEKARANG'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
