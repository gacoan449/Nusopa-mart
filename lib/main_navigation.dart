import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'live_screen.dart';       
import 'pesanan_screen.dart';    
import 'chat_list_screen.dart';  
import 'profil_screen.dart';     

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Menyusun halaman yang akan dikunci memorinya di latar belakang
  final List<Widget> _pages = [
    const HomeScreen(),       
    const LiveScreen(),       
    const PesananScreen(),    
    const ChatListScreen(),   
    const ProfilScreen(),     
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // PERBAIKAN 1: Menggunakan IndexedStack agar posisi scroll & data Firebase tidak reload ulang saat pindah tab
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      // PERBAIKAN 2: Menggunakan Theme khusus untuk memberi jarak aman dari navigasi gestur HP modern
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 4,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          // PERBAIKAN 3: Mengubah identitas warna dari Biru ke Oranye Premium COD Nusopa
          selectedItemColor: Colors.orange.shade800, 
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.2),
          unselectedLabelStyle: const TextStyle(fontSize: 11, letterSpacing: 0.2),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 22), 
              activeIcon: Icon(Icons.home, size: 22),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.live_tv_outlined, size: 22), 
              activeIcon: Icon(Icons.live_tv, size: 22),
              label: 'Live',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined, size: 22), 
              activeIcon: Icon(Icons.assignment, size: 22),
              label: 'Pesanan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline, size: 22), 
              activeIcon: Icon(Icons.chat_bubble, size: 22),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 22), 
              activeIcon: Icon(Icons.person, size: 22),
              label: 'Saya',
            ),
          ],
        ),
      ),
    );
  }
}
