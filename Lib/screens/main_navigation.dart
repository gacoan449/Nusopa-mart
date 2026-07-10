import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'live_screen.dart';       // Menghubungkan Menu Live
import 'chat_list_screen.dart';  // Menghubungkan Kotak Masuk Pesan
import 'pesanan_screen.dart';
import 'profil_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const LiveScreen(),       // Tab 2: Fitur Shopee Live Lite
    const PesananScreen(),    // Tab 3: Riwayat Resi & Pengiriman COD
    const ChatListScreen(),   // Tab 4: Kotak Masuk Pesan Realtime
    const ProfilScreen(),     // Tab 5: Akun Saya & Dashboard Admin
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'Live'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Pesanan'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Saya'),
        ],
      ),
    );
  }
}
