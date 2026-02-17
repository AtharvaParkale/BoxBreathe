import 'package:audioplayers/audioplayers.dart';

class SoundService {
  final AudioPlayer _player = AudioPlayer();
  
  SoundService() {
    _init();
  }

  Future<void> _init() async {
    // Preload the beep sound
    await _player.setSource(AssetSource('audio/breath_beep.mp3'));
    await _player.setVolume(0.3); // Low and calming volume
  }

  Future<void> playBeep() async {
    // Reuse the same player instance, reset and play
    await _player.stop();
    await _player.resume();
  }

  void dispose() {
    _player.dispose();
  }
}
