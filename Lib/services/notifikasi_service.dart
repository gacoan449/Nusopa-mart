import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Handler saat aplikasi ditutup (Background/Terminated) - Menggunakan notifikasi standar
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  NotifikasiService.tampilkanNotifikasiStandar(message);
}

class NotifikasiService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Channel standar menggunakan suara default bawaan HP
  static const AndroidNotificationChannel _saluranStandar =
      AndroidNotificationChannel(
    'nusopa_default_channel', 
    'Notifikasi Transaksi Nusopa',
    description: 'Pemberitahuan pesanan masuk dan tiket baru',
    importance: Importance.max,
    playSound: true, // Menggunakan suara bawaan sistem HP
  );

  static Future<void> inisialisasiNotifikasi() async {
    // 1. Meminta izin dasar untuk iOS
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Meminta izin eksplisit untuk Android 13 ke atas
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    }

    // 3. Mendaftarkan channel standar ke dalam sistem OS Android
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(_saluranStandar);
      }
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    // 4. Inisialisasi aksi saat notifikasi di-klik oleh user
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        String? dataPayload = response.payload;
        if (dataPayload != null) {
          // Tempat untuk mengarahkan halaman jika notifikasi diklik
        }
      },
    );

    // Menerima notifikasi saat aplikasi sedang dibuka aktif (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      tampilkanNotifikasiStandar(message);
    });

    // Menerima notifikasi saat aplikasi mati / di latar belakang (Background)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> tampilkanNotifikasiStandar(RemoteMessage message) async {
    // Menggunakan konfigurasi default Android tanpa file audio eksternal
    final androidDetails = AndroidNotificationDetails(
      _saluranStandar.id,
      _saluranStandar.name,
      channelDescription: _saluranStandar.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true, // Aktif menggunakan suara bawaan HP
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    String? payloadString = message.data.isNotEmpty ? message.data.toString() : null;

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // ID acak berbasis waktu agar tidak menimpa notifikasi lain
      message.notification?.title ?? "Nusopa Mart",
      message.notification?.body ?? "Ada pembaruan transaksi baru!",
      notificationDetails,
      payload: payloadString,
    );
  }
}
