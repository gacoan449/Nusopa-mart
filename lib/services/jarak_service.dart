import 'dart:math';
import 'package:geolocator/geolocator.dart';

class JarakService {
  
  // PERBAIKAN 1 & 3: Mengambil lokasi dengan cepat tanpa membuat aplikasi stuck loading lama
  static Future<Position?> ambilLokasiSekarang() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek apakah layanan GPS di HP aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    // Cek izin akses GPS
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) return null;

    try {
      // Optimasi Kecepatan: Ambil lokasi terakhir yang tersimpan di memori HP (Instan 0 detik)
      Position? posisiTerakhir = await Geolocator.getLastKnownPosition();
      if (posisiTerakhir != null) {
        return posisiTerakhir;
      }

      // Jika lokasi terakhir kosong, baru cari satelit GPS dengan batas waktu (timeout) aman
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, // Akurasi tinggi untuk deteksi kurir/seller COD
          timeLimit: Duration(seconds: 5),  // Batasi maksimal 5 detik agar aplikasi tidak hang
        ),
      );
    } catch (e) {
      // Jika terjadi eror sistem GPS, kembalikan null dengan aman agar aplikasi tidak crash
      return null;
    }
  }

  // PERBAIKAN 2: Rumus Haversine dengan pembulatan numerik yang aman dari crash
  static double hitungJarakKm(double lat1, double lon1, double lat2, double lon2) {
    // Validasi Pengaman: Jika koordinat identik, jaraknya pasti 0
    if (lat1 == lat2 && lon1 == lon2) return 0.0;

    var p = 0.017453292519943295; // Konstanta Pi / 180
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p))/2;
          
    double hasilKm = 12742 * asin(sqrt(a)); // 12742 adalah diameter bumi

    // Pembulatan aman ke 1 angka di belakang koma tanpa mengubah ke String (Mencegah Crash Parse)
    return (hasilKm * 10).round() / 10;
  }
}
