import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'auth_screen.dart';
import 'main_navigation.dart';
import 'services/notifikasi_service.dart'; 

void main() async {
  // Memastikan binding Flutter siap sebelum inisialisasi async
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Firebase Utama (Gunakan opsi credential proyek Anda)
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB-guTai42pYgcvXeacyt_8fyUpkfxzluA",
      appId: "1:242778852239:android:c046739230c32971fe99fa", 
      messagingSenderId: "242778852239",
      projectId: "desapay-10614",
      storageBucket: "desapay-10614.firebasestorage.app",
    ),
  );

  // PERBAIKAN 1: Inisialisasi Notifikasi Standar Sistem (Tanpa Audio Eksternal rujukan lama)
  await NotifikasiService.inisialisasiNotifikasi();
  
  // Otomatis berlangganan topik promo belanja nusopa
  try {
    await FirebaseMessaging.instance.subscribeToTopic("nusopa_promo");
  } catch (e) {
    debugPrint("Gagal subscribe topik: $e");
  }

  runApp(const NusopaMartApp());
}

class NusopaMartApp extends StatelessWidget {
  const NusopaMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nusopa Mart',
      debugShowCheckedModeBanner: false,
      // PERBAIKAN 4: Mengubah tema dasar aplikasi menjadi Oranye Premium COD Nusopa
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange.shade800,
          primary: Colors.orange.shade800,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade50,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.orange),
              ),
            );
          }
          
          // PERBAIKAN 2: Manajemen perpindahan halaman tanpa loop update token FCM
          if (snapshot.hasData && snapshot.data != null) {
            return const MainNavigation();
          }
          
          return const AuthScreen();
        },
      ),
    );
  }
}
