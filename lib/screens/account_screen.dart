import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'orders_screen.dart';
import 'seller_dashboard.dart';
import 'rekber_info_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  static const blue = Color(0xFF126BFF);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Saya'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFEAF3FF),
                child: Icon(Icons.person, color: blue, size: 34),
              ),
              title: Text(
                'Akun Nusopa.Mart',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              subtitle: Text(user?.email ?? 'Pengguna'),
            ),
          ),
          const SizedBox(height: 10),
          _tile(
            context,
            Icons.receipt_long_outlined,
            'Pesanan Saya',
            'Status dan detail transaksi',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),
          ),
          _tile(
            context,
            Icons.storefront_outlined,
            'Jual Barang',
            'Kelola toko, produk, stok dan pesanan',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SellerDashboard()),
            ),
          ),
          _tile(
            context,
            Icons.shield_outlined,
            'Aturan & Rekber',
            'Biaya, alur, keamanan dan sengketa',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RekberInfoScreen()),
            ),
          ),
          _tile(
            context,
            Icons.settings_outlined,
            'Pengaturan',
            'Notifikasi, keamanan dan preferensi',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Keluar'),
              onTap: () => FirebaseAuth.instance.signOut(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: blue.withValues(alpha: 0.1),
          child: Icon(icon, color: blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool all = true;
  bool orders = true;
  bool chat = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            child: Column(
              children: [
                const ListTile(
                  title: Text(
                    'Notifikasi',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                SwitchListTile(
                  value: all,
                  onChanged: (value) => setState(() => all = value),
                  title: const Text('Notifikasi aplikasi'),
                  subtitle: const Text('Promo dan informasi penting'),
                  secondary: const Icon(Icons.notifications_none),
                ),
                SwitchListTile(
                  value: orders,
                  onChanged: all ? (value) => setState(() => orders = value) : null,
                  title: const Text('Update pesanan'),
                  secondary: const Icon(Icons.local_shipping_outlined),
                ),
                SwitchListTile(
                  value: chat,
                  onChanged: all ? (value) => setState(() => chat = value) : null,
                  title: const Text('Notifikasi chat'),
                  secondary: const Icon(Icons.chat_bubble_outline),
                ),
              ],
            ),
          ),
          Card(
            elevation: 0,
            child: Column(
              children: [
                const ListTile(
                  title: Text(
                    'Keamanan',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Keamanan akun'),
                  subtitle: Text('Jangan bagikan password, OTP atau PIN.'),
                ),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Perlindungan Rekber'),
                  subtitle: const Text('Baca aturan transaksi'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RekberInfoScreen()),
                  ),
                ),
              ],
            ),
          ),
          Card(
            elevation: 0,
            child: Column(
              children: [
                const ListTile(
                  title: Text(
                    'Tentang aplikasi',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Tentang Nusopa.Mart'),
                  subtitle: const Text('Marketplace dengan alur Rekber'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RekberInfoScreen()),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.verified_outlined),
                  title: Text('Versi aplikasi'),
                  trailing: Text('1.0.0+1'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
