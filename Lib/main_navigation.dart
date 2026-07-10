import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'live_screen.dart';       // Mengimpor menu Live Streaming Baru
import 'keranjang_screen.dart';  // Mengimpor menu Keranjang Belanja COD
import 'pesanan_screen.dart';    // Mengimpor menu Status Transaksi Resi
import 'chat_list_screen.dart';  // Mengimpor menu Kotak Masuk Chat Realtime
import 'profil_screen.dart';     // Mengimpor menu Akun Saya & Dashboard Admin

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Menyusun 6 Fitur Utama ke dalam 5 Tab Menu Bawah (Keranjang disematkan di dalam Bar Atas / AppBar)
  // Ini adalah susunan terbaik standar industri agar menu bawah tidak terlalu sesak (Maksimal 5 item)
  final List<Widget> _pages = [
    const HomeScreen(),       // Tab 1: Beranda Produk & Urutan Bintang 5
    const LiveScreen(),       // Tab 2: Fitur Shopee LIVE Lite
    const PesananScreen(),    // Tab 3: Logistik Pengiriman & Input Resi Manual
    const ChatListScreen(),   // Tab 4: Kotak Masuk Pesan Realtime COD
    const ProfilScreen(),     // Tab 5: Akun Saya & Ruang Dashboard Admin
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
        selectedItemColor: Colors.blue.shade700, // Identitas warna biru premium Nusopa
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), 
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.live_tv_outlined), 
            activeIcon: Icon(Icons.live_tv),
            label: 'Live',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined), 
            activeIcon: Icon(Icons.assignment),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline), 
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), 
            activeIcon: Icon(Icons.person),
            label: 'Saya',
          ),
        ],
      ),
    );
  }
}
