import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Tambahkan impor ini jika belum ada
import 'package:cloud_firestore/cloud_firestore.dart'; // Tambahkan impor ini jika belum ada
import 'package:firebase_messaging/firebase_messaging.dart'; // Tambahkan impor ini jika belum ada
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

  final List<Widget> _pages = [
    const HomeScreen(),       
    const LiveScreen(),       
    const PesananScreen(),    
    const ChatListScreen(),   
    const ProfilScreen(),     
  ];

  // KODE MASUK DI SINI: Siklus initState mendeteksi pembukaan navigasi pertama
  @override
  void initState() {
    super.initState();
    _simpanTokenFcmKeDatabase(); // Eksekusi otomatis satu kali saja
  }

  // FUNGSI UPDATE FCM TOKEN YANG AMAN DAN HEMAT KUOTA FIRESTORE
  void _simpanTokenFcmKeDatabase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          // Hanya memperbarui token perangkat tanpa mengganggu widget lain
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'fcm_token': token,
          });
        }
      } catch (e) {
        debugPrint("Token FCM gagal disimpan: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
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
