import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/cart_service.dart';
import '../services/rekber_service.dart';

class CheckoutScreen extends StatefulWidget {
  final String? sellerId;
  final String? productId;
  final String? productName;
  final int? price;
  final List<Map<String, dynamic>>? items;

  const CheckoutScreen({
    super.key,
    this.sellerId,
    this.productId,
    this.productName,
    this.price,
    this.items,
  });

  const CheckoutScreen.cart({super.key, required this.items})
      : sellerId = null,
        productId = null,
        productName = null,
        price = null;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const blue = Color(0xFF126BFF);
  int qty = 1;
  final shipping = TextEditingController(text: '0');
  bool loading = false;

  int val(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value.toString()) ?? 0;

  String money(int value) =>
      'Rp${value.toString().replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (_) => '.')}';

  Future<List<Map<String, dynamic>>> resolve() async {
    if (widget.items != null) {
      final result = <Map<String, dynamic>>[];
      for (final raw in widget.items!) {
        final id = (raw['productId'] ?? raw['cartId'] ?? '').toString();
        final snapshot = await FirebaseFirestore.instance
            .collection('products')
            .doc(id)
            .get();
        final product = snapshot.data();
        if (product == null || !snapshot.exists) {
          throw Exception('Produk tidak tersedia');
        }
        final price = val(product['price'] ?? product['productPrice']);
        final stock = val(product['stock']);
        final quantity = val(raw['qty']);
        if (price <= 0 || quantity <= 0 || stock < quantity) {
          throw Exception('Stok tidak mencukupi untuk ${product['name'] ?? 'produk'}');
        }
        result.add({
          'productId': id,
          'sellerId': (product['sellerId'] ?? '').toString(),
          'productName':
              (product['name'] ?? product['productName'] ?? 'Produk').toString(),
          'price': price,
          'qty': quantity,
        });
      }
      return result;
    }

    if (widget.sellerId == null ||
        widget.productId == null ||
        widget.productName == null ||
        widget.price == null) {
      throw Exception('Data checkout tidak lengkap');
    }

    return [
      {
        'sellerId': widget.sellerId!,
        'productId': widget.productId!,
        'productName': widget.productName!,
        'price': widget.price!,
        'qty': qty,
      },
    ];
  }

  Future<void> submit() async {
    final ship = val(shipping.text);
    if (ship < 0) return;

    setState(() => loading = true);
    try {
      final items = await resolve();
      final orderIds = <String>[];

      for (final item in items) {
        orderIds.add(
          await RekberService.instance.createOrder(
            sellerId: item['sellerId'],
            productId: item['productId'],
            productName: item['productName'],
            price: item['price'],
            qty: item['qty'],
            shippingCost: ship,
          ),
        );
      }

      if (widget.items != null) {
        await CartService.instance.clear();
      }

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Order berhasil dibuat'),
          content: Text(
            'ID Order: ${orderIds.join(', ')}\n'
            'Total sudah termasuk biaya Rekber Rp3.000 per order.\n\n'
            'Ikuti instruksi pembayaran resmi Admin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout gagal: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCart = widget.items != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Checkout'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isCart)
            ...widget.items!.map(
              (item) => Card(
                elevation: 0,
                child: ListTile(
                  title: Text('${item['productName'] ?? 'Produk'}'),
                  subtitle: Text('Jumlah ${val(item['qty'])}'),
                  trailing: Text(
                    money(val(item['price']) * val(item['qty'])),
                    style: const TextStyle(fontWeight: FontWeight.w800, color: blue),
                  ),
                ),
              ),
            )
          else
            Card(
              elevation: 0,
              child: ListTile(
                title: Text(widget.productName ?? 'Produk'),
                subtitle: Text(money((widget.price ?? 0) * qty)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: qty > 1 ? () => setState(() => qty--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$qty'),
                    IconButton(
                      onPressed: () => setState(() => qty++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          _summary(),
          const SizedBox(height: 12),
          TextField(
            controller: shipping,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Biaya ekspedisi',
              prefixText: 'Rp ',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Biaya Rekber: Rp3.000 per order. Pembayaran hanya melalui '
                'instruksi resmi Admin. Jangan kirim OTP, PIN, atau dana kepada pihak lain.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: loading ? null : submit,
            style: FilledButton.styleFrom(
              backgroundColor: blue,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.lock_outline),
            label: Text(loading ? 'MEMPROSES...' : 'BUAT ORDER DENGAN REKBER'),
          ),
        ],
      ),
    );
  }

  Widget _summary() {
    var subtotal = 0;
    var fee = 3000;

    if (widget.items != null) {
      subtotal = widget.items!.fold(
        0,
        (sum, item) => sum + val(item['price']) * val(item['qty']),
      );
      fee = widget.items!.length * 3000;
    } else {
      subtotal = (widget.price ?? 0) * qty;
    }

    final ship = val(shipping.text);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Subtotal produk', money(subtotal)),
            _row('Biaya Rekber', money(fee)),
            _row('Ekspedisi', money(ship)),
            const Divider(),
            _row('Total pembayaran', money(subtotal + fee + ship)),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 13))),
            Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          ],
        ),
      );

  @override
  void dispose() {
    shipping.dispose();
    super.dispose();
  }
}
