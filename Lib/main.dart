import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'auth_screen.dart';
import 'main_navigation.dart';
import 'services/notifikasi_service.dart'; 

// Fungsi khusus pemutar suara notifikasi di latar belakang (saat aplikasi ditutup)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB-guTai42pYgcvXeacyt_8fyUpkfxzluA",
      appId: "1:242778852239:android:c046739230c32971fe99fa", 
      messagingSenderId: "242778852239",
      projectId: "desapay-10614",
      storageBucket: "desapay-10614.firebasestorage.app",
    ),
  );
  await NotifikasiService.tampilkanNotifikasiSuara(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB-guTai42pYgcvXeacyt_8fyUpkfxzluA",
      appId: "1:242778852239:android:c046739230c32971fe99fa", 
      messagingSenderId: "242778852239",
      projectId: "desapay-10614",
      storageBucket: "desapay-10614.firebasestorage.app",
    ),
  );

  await NotifikasiService.inisialisasiNotifikasi();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.subscribeToTopic("nusopa_promo");

  runApp(const NusopaMartApp());
}

class NusopaMartApp extends StatelessWidget {
  const NusopaMartApp({super.key});

  // Fungsi pembaruan token dipindahkan ke lokasi statis yang aman agar tidak merusak siklus widget
  static void perbaruiTokenNotifikasiUser(String uid) async {
    try {
      String? tokenFcm = await FirebaseMessaging.instance.getToken();
      if (tokenFcm != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcm_token': tokenFcm,
        });
      }
    } catch (e) {
      // Mengabaikan eror log jika perangkat tidak mendukung token fcm
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nusopa Mart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // REVISI SAKTI: Memperbaiki format penulisan ColorScheme agar lolos tanpa fitur eksperimental
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            perbaruiTokenNotifikasiUser(snapshot.data!.uid);
            return const MainNavigation();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}
