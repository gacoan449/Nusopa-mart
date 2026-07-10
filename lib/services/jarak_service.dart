import 'dart:math';
import 'package:geolocator/geolocator.dart';

class JarakService {
  // Fungsi 1: Meminta izin GPS dan mengambil lokasi koordinat HP pembeli saat ini
  static Future<Position?> ambilLokasiSekarang() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  // Fungsi 2: Rumus Haversine untuk menghitung jarak (KM) antara Pembeli dan Penjual
  static double hitungJarakKm(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // Konstanta Pi / 180
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p))/2;
          
    double hasilKm = 12742 * asin(sqrt(a)); // 12742 adalah diameter bumi
    return double.parse(hasilKm.toStringAsFixed(1)); // Mengembalikan angka dengan 1 angka di belakang koma (misal: 1.5 km)
  }
}
