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
    // Stop any existing playback to ensure clean restart
    await _player.stop();
    // Use play() with the source explicitly to ensure it starts from the beginning every time
    await _player.play(AssetSource('audio/breath_beep.mp3'), volume: 0.3);
  }

  void dispose() {
    _player.dispose();
  }
}
