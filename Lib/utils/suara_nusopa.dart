import 'package:audioplayers/audioplayers.dart';

class SuaraNusopa {
  static final AudioPlayer _pemutar = AudioPlayer();

  static Future<void> mainNotif() async {
    await _pemutar.play(
      RawAssetSource('nusopa_notif.mp3'),
      volume: 1.0,
    );
  }

  static void tutup() {
    _pemutar.dispose();
  }
}
