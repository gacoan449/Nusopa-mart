import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications;

class NotifikasiService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // 1. Inisialisasi Sistem Notifikasi & Setup Suara Khas
  static Future<void> inisialisasiNotifikasi() async {
    // Meminta izin notifikasi ke pengguna HP (Sangat penting untuk Android 13 ke atas)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);

    // Mendengarkan notifikasi masuk saat aplikasi sedang dibuka/aktif (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      tampilkanNotifikasiSuara(message);
    });
  }

  // 2. Fungsi Menampilkan Kotak Notifikasi + Memutar Suara Kustom ala Shopee
  static Future<void> tampilkanNotifikasiSuara(RemoteMessage message) async {
    try {
      // PENTING: Nama file suara di bawah ini (nusopa_sound) tidak boleh pakai ekstensi .mp3 di dalam kode Flutter
      AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'nusopa_channel_id', // ID Channel bebas
        'Notifikasi Transaksi Nusopa', // Nama Channel bebas
        channelDescription: 'Mendengar suara pesanan masuk dan tiket baru',
        importance: Importance.max,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('nusopa_sound'), // KUNCI SUARA KHAS ANDA DI SINI
        playSound: true,
      );

      NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

      await _notificationsPlugin.show(
        DateTime.now().hashCode, // ID notifikasi acak agar tidak saling menimpa
        message.notification?.title ?? "Nusopa Mart",
        message.notification?.body ?? "Ada pembaruan transaksi baru!",
        notificationDetails,
      );
    } catch (e) {
      // Batasan penanganan eror sederhana jika file suara belum siap di sistem HP
    }
  }
}
