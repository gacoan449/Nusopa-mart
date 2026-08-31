import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'seller_dashboard.dart';
import 'admin_core.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _noHp = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _noHp.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_noHp.text.trim().isEmpty || _password.text.isEmpty) {
      _show('Nomor HP dan password wajib diisi.');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ApiService.instance.login(
        noHp: _noHp.text.trim(),
        password: _password.text,
      );
      final role = (result['user']?['role'] ?? '').toString().toUpperCase();
      if (!mounted) return;

      Widget page;
      switch (role) {
        case 'ADMIN':
          page = const SuperAdminDashboard();
          break;
        case 'SELLER':
          page = const SellerDashboard();
          break;
        default:
          page = const HomeScreen();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => page),
      );
    } catch (e) {
      _show(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF5722);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.storefront, size: 72, color: orange),
                  const SizedBox(height: 16),
                  Text('Nusopa.Mart',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('Marketplace dengan Rekber Admin',
                    textAlign: TextAlign.center),
                  const SizedBox(height: 36),
                  TextField(
                    controller: _noHp,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor HP',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _password,
                    obscureText: !_showPassword,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('MASUK'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Admin, Seller, dan Pembeli menggunakan autentikasi backend. Tidak ada password Admin di dalam APK.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
