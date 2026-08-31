import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError('Platform belum dikonfigurasi. Jalankan flutterfire configure untuk iOS/Web.');
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB-guTai42pYgcvXeacyt_8fyUpkfxzluA',
    appId: '1:242778852239:android:746f364459e64879fe99fa',
    messagingSenderId: '242778852239',
    projectId: 'desapay-10614',
    storageBucket: 'desapay-10614.firebasestorage.app',
  );
}
