import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotifikasiService {
  static final FlutterLocalNotificationsPlugin
      _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> inisialisasiNotifikasi() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(settings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      tampilkanNotifikasiSuara(message);
    });
  }

  static Future<void> tampilkanNotifikasiSuara(
      RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'nusopa_channel_id',
      'Notifikasi Transaksi Nusopa',
      channelDescription:
          'Mendengar suara pesanan masuk dan tiket baru',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('nusopa_sound'),
      playSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? "Nusopa Mart",
      message.notification?.body ?? "Ada pembaruan transaksi baru!",
      notificationDetails,
    );
  }
}
