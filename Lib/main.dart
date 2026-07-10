import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'auth_screen.dart';
import 'main_navigation.dart';
import 'services/notifikasi_service.dart'; 

// Fungsi khusus pemutar suara notifikasi di latar belakang (saat aplikasi ditutup)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inisialisasi ulang dengan parameter keras (hardcoded) yang sama agar background proses mengenali database
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB-guTai42pYgcvXeacyt_8fyUpkfxzluA",
      appId: "1:242778852239:android:c046739230c32971fe99fa", // Menggunakan AppID untuk com.nusopa.mart
      messagingSenderId: "242778852239",
      projectId: "desapay-10614",
      storageBucket: "desapay-10614.firebasestorage.app",
    ),
  );
  await NotifikasiService.tampilkanNotifikasiSuara(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // KUNCI JAWABAN: Inisialisasi Firebase Keras langsung di deretan lib/main.dart tanpa file JSON luar!
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB-guTai42pYgcvXeacyt_8fyUpkfxzluA",
      appId: "1:242778852239:android:c046739230c32971fe99fa", // Mengunci identitas paket com.nusopa.mart
      messagingSenderId: "242778852239",
      projectId: "desapay-10614",
      storageBucket: "desapay-10614.firebasestorage.app",
    ),
  );

  // Setup pemicu suara dan penerima sinyal iklan massal 1 hari 2 kali
  await NotifikasiService.inisialisasiNotifikasi();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.subscribeToTopic("nusopa_promo");

  runApp(const NusopaMartApp());
}

class NusopaMartApp extends StatelessWidget {
  const NusopaMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nusopa Mart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue.shade700,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            _perbaruiTokenNotifikasiUser(snapshot.data!.uid);
            return const MainNavigation();
          }
          return const AuthScreen();
        },
      ),
    );
  }

  void _perbaruiTokenNotifikasiUser(String uid) async {
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
}
