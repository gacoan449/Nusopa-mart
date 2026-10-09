# Nusopa.Mart — Marketplace Jawa Tengah

Nusopa.Mart sedang dibangun ulang bertahap untuk menjadi marketplace lokal Jawa Tengah dengan aplikasi pelanggan, layanan kurir, seller, dan panel admin.

## Sasaran produk
- Katalog sembako, hasil tani, sayur/buah, ayam/telur yang dikelola Nusopa.
- Seller pihak ketiga dapat menawarkan kategori lain seperti elektronik.
- Rencana komisi marketplace seller pihak ketiga: 3%; aturan final harus dikelola admin dan ditampilkan transparan sebelum seller bergabung.
- Keranjang, checkout, status pesanan, pengiriman, dan riwayat transaksi.
- Peta aplikasi menggunakan MapLibre dengan sumber data peta yang mematuhi lisensi/provider; navigasi eksternal dapat membuka Google Maps melalui URL.
- Aplikasi kurir dengan tugas pengantaran dan pembaruan lokasi, setelah backend dan izin lokasi disiapkan.
- Panel admin untuk produk, seller, order, kurir, komisi, dan moderasi.

## Status saat ini
Branch `rewrite/central-java-marketplace` memulai pembaruan UI katalog Flutter. Katalog dan keranjang yang terlihat pada tahap ini masih menggunakan data contoh lokal. Login, sinkronisasi Firebase, checkout sungguhan, komisi yang dihitung server, peta langsung, GPS kurir, pembayaran, dan panel admin belum boleh dianggap selesai hanya dari tampilan ini.

## Arsitektur yang dituju
- Flutter Android untuk pelanggan; mode kurir dapat dipisah menjadi aplikasi tersendiri setelah alur inti stabil.
- Firebase Authentication untuk identitas.
- Cloud Firestore dengan aturan akses ketat untuk katalog, seller, order, dan status pengantaran.
- Cloud Functions/backend tepercaya untuk menghitung harga/komisi, validasi order, dan perubahan status sensitif.
- Firebase Storage untuk gambar produk dengan aturan ukuran/tipe file.
- MapLibre untuk peta; layanan routing yang sesuai batas penggunaan atau server routing sendiri saat skala bertambah.
- Google Maps Intent/URL untuk navigasi eksternal tanpa perlu menanam API key Maps hanya untuk membuka aplikasi navigasi.

## Prinsip keamanan
- Jangan menyimpan rahasia server atau private key di aplikasi.
- Harga, diskon, komisi 3%, pembayaran, dan status order harus divalidasi di backend, bukan dipercaya dari aplikasi klien.
- Jangan memberi klien hak menulis saldo/wallet atau mengubah status pembayaran terverifikasi.
- Uji aturan Firestore dan Storage dengan akun buyer, seller, kurir, dan admin yang berbeda.
- Gunakan transaksi uji dan data non-sensitif sampai audit keamanan serta pengujian end-to-end selesai.

## Cara kerja pengembangan
1. Periksa perubahan pada branch rewrite terlebih dahulu.
2. Jalankan `flutter pub get`, `flutter analyze`, dan `flutter test` di lingkungan Flutter.
3. Integrasikan Firebase, autentikasi, katalog dinamis, dan peran pengguna.
4. Implementasikan order/komisi tepercaya dan aturan akses.
5. Tambahkan alamat, peta, estimasi rute, serta alur kurir.
6. Bangun APK pengujian dan lakukan uji end-to-end sebelum rilis.

Branch `main` tetap menjadi versi awal. Jangan menganggap aplikasi siap produksi hanya karena APK berhasil dibuat.
