# Nusopa.Mart

Nusopa.Mart adalah aplikasi komunitas + marketplace dengan **Rekber manual**. Aplikasi Android menggunakan Flutter dan Firebase. Dana transaksi **tidak dipindahkan melalui API, wallet aplikasi, atau saldo Firestore**; pembayaran dilakukan ke rekening/lembaga yang telah disiapkan, lalu status transaksi dikelola melalui proses verifikasi admin.

## Arsitektur aktif
- Flutter: aplikasi Android.
- Firebase Authentication: akun/login.
- Cloud Firestore: profil sosial, feed, komunitas, chat, order, bukti pembayaran, status Rekber, dan permintaan pencairan.
- Firebase Storage: foto dan bukti pembayaran.
- Firestore Security Rules: membatasi siapa yang boleh membaca/mengubah data.

## Alur Rekber
`MENUNGGU_PEMBAYARAN` → `MENUNGGU_VERIFIKASI` → `DIPROSES` → `SIAP_DIKIRIM` → `DIKIRIM` → `DITERIMA`

Pembayaran eksternal tetap harus diverifikasi admin. Status finansial tidak boleh dibuat seolah-olah berhasil hanya karena pengguna mengunggah bukti transfer.

## Fitur sosial
- Feed postingan.
- Foto postingan.
- Like.
- Komentar.
- Follow/follower.
- Notifikasi aktivitas.
- Direct chat.
- Komunitas/grup.
- Share/repost ke feed.
- Pelaporan postingan untuk moderasi admin.

## Fitur marketplace
- Toko dan produk.
- Keranjang.
- Checkout.
- Order dan tracking.
- Bukti pembayaran.
- Proses pengiriman.
- Withdrawal seller untuk diproses admin.

## Keamanan penting
Client tidak diberi izin menulis collection `wallets`. Nilai order, payment status, dan perubahan status Rekber dibatasi oleh rules. Admin adalah pihak yang memverifikasi pembayaran eksternal dan menangani penyelesaian transaksi.

Folder `backend/` adalah komponen API lama/eksperimental dan **bukan jalur runtime aplikasi Flutter saat ini**. Jangan menjalankan atau mengandalkannya untuk transaksi Nusopa tanpa keputusan arsitektur baru.

## Build pengujian
GitHub Actions menjalankan `flutter pub get`, `flutter analyze`, `flutter test`, build App Bundle release, dan build APK debug untuk perangkat pengujian. Artifact APK pengujian diberi nama `nusopa-mart-testing-apk`.

## Checklist sebelum dibagikan
1. Deploy `firestore.rules` terbaru ke Firebase.
2. Pastikan Email/Password Authentication aktif.
3. Pastikan Firebase Storage aktif.
4. Uji akun pembeli dan seller dengan data terpisah.
5. Uji order → upload bukti → verifikasi admin → proses → kirim → diterima.
6. Uji bahwa user biasa tidak dapat mengubah wallet/payment verification.
7. Uji posting → like → komentar → follow → share/repost → report.
8. Uji direct chat dan grup.
9. Pastikan workflow GitHub menghasilkan APK debug yang dapat dipasang di HP penguji.

## Catatan
Build uji coba bukan berarti sistem sudah siap menerima dana publik tanpa pengujian operasional, SOP admin, dan kepastian hukum/kelembagaan Rekber. Untuk malam ini, gunakan transaksi nominal uji dan data non-sensitif terlebih dahulu.
