import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Impor pustaka fcm cloud
import 'auth_screen.dart';
import 'main_navigation.dart';
import 'services/notifikasi_service.dart'; // Impor peluncur suara notifikasi kustom

// Fungsi khusus latar belakang (Background/Background Handler) 
// Wajib ditaruh di paling luar class agar aplikasi tetap bisa memutar suara saat HP terkunci/ditutup
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotifikasiService.tampilkanNotifikasiSuara(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Menghubungkan Flutter ke Firebase cloud Anda

  // 1. Setup Pemicu Notifikasi Suara Khas Shopee Style (Aplikasi Terbuka)
  await NotifikasiService.inisialisasiNotifikasi();

  // 2. Setup Pendengar Sinyal Latar Belakang (Aplikasi Ditutup / Terkunci)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. Taktik Anti-Spam Shopee: Daftarkan Semua Pembeli ke Topik Iklan Bergantian
  // Cukup kirim pesan broadcast lewat Firebase Console maksimal 1-2 kali sehari
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
      // StreamBuilder memantau status sesi login pengguna secara realtime
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // Jika user sukses login, pemicu token fcm akan mengaitkan akunnya 
          // ke sistem database biar seller dapet notif orderan masuk otomatis
          if (snapshot.hasData) {
            _perbaruiTokenNotifikasiUser(snapshot.data!.uid);
            return const MainNavigation();
          }
          
          // Jika pengguna baru / belum login, arahkan ke gerbang AuthScreen
          return const AuthScreen();
        },
      ),
    );
  }

  // Fungsi menyimpan Token HP unik pengguna ke Firestore
  // Berguna agar sistem bisa menembak notifikasi khusus ke seller tertentu saat barangnya dibeli
  void _perbaruiTokenNotifikasiUser(String uid) async {
    try {
      String? tokenFcm = await FirebaseMessaging.instance.getToken();
      if (tokenFcm != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcm_token': tokenFcm, // Token disimpan untuk target tembakan notifikasi personal
        });
      }
    } catch (e) {
      // Pembatasan penanganan eror jika device menolak fcm token token
    }
  }
}
