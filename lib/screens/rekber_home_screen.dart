import 'package:flutter/material.dart';
import '../services/rekber_service.dart';

class RekberHomeScreen extends StatelessWidget {
  const RekberHomeScreen({super.key});

  String money(dynamic value) {
    final number = int.tryParse('$value') ?? 0;
    return 'Rp${number.toString().replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (_) => '.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rekber')),
      body: StreamBuilder(
        stream: RekberService.instance.buyerOrders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _ConnectionStateView(
              message: 'Gagal memuat transaksi. Periksa koneksi Anda.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final active = docs
              .where((d) => !['SELESAI', 'DIBATALKAN'].contains(
                    d.data()['statusPesanan'] ?? d.data()['status'],
                  ))
              .toList();
          final history = docs
              .where((d) => ['SELESAI', 'DIBATALKAN'].contains(
                    d.data()['statusPesanan'] ?? d.data()['status'],
                  ))
              .toList();

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                FilledButton.icon(
                  onPressed: () => _invoice(context),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Buat Invoice Rekber'),
                ),
                const SizedBox(height: 18),
                _section('Transaksi Aktif', active),
                const SizedBox(height: 18),
                _section('Riwayat', history),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(String title, List<dynamic> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (docs.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Belum ada transaksi.'),
            ),
          ),
        ...docs.map((doc) {
          final d = doc.data();
          return Card(
            child: ListTile(
              title: Text(d['productName'] ?? d['namaProduk'] ?? 'Transaksi'),
              subtitle: Text(
                d['statusPesanan'] ?? d['status'] ?? 'MENUNGGU',
              ),
              trailing: Text(
                money(d['total'] ?? d['totalPembayaran']),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _invoice(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('Invoice Rekber'),
        content: Text(
          'Invoice dibuat dari transaksi marketplace yang sudah memiliki penjual dan nominal tervalidasi server.',
        ),
      ),
    );
  }
}

class _ConnectionStateView extends StatelessWidget {
  final String message;

  const _ConnectionStateView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
