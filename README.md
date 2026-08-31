# Nusopa.Mart

Flutter + Firebase marketplace dengan alur pembayaran Rekber manual.

## Arsitektur
- Firebase Authentication: login akun
- Cloud Firestore: order, pembayaran, pengiriman, wallet, withdrawal
- Firebase Storage: bukti pembayaran/foto
- Flutter: aplikasi Android

## Status Rekber
MENUNGGU_PEMBAYARAN -> MENUNGGU_VERIFIKASI -> TERKUNCI -> DIKIRIM -> SELESAI -> DANA_TERSEDIA

Withdrawal:
MENUNGGU_ADMIN -> DISETUJUI -> DITRANSFER

## Firebase yang sudah ditemukan
Project ID: `desapay-10614`

> File yang terupload sebelumnya bernama `google-services..json` (dua titik). Android mengharuskan nama tepat `google-services.json`.

## Penting untuk uang/saldo
Flutter client tidak boleh diberi izin langsung mengubah saldo wallet. Untuk sistem uang produksi gunakan Firebase Cloud Functions/Admin SDK untuk verifikasi pembayaran, pelepasan dana, dan withdrawal. Rules Firestore saja tidak dapat menggantikan logika server tepercaya untuk transaksi finansial.

## Setup
1. Pastikan Firebase Authentication Email/Password aktif.
2. Aktifkan Firestore dan Storage.
3. Upload `android/app/google-services.json`.
4. Buat project Android Flutter lengkap bila folder android belum berisi Gradle wrapper/build files.
5. Jalankan `flutter pub get`.
6. Jalankan `flutter analyze`.
