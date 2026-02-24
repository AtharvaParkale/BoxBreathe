import 'package:audioplayers/audioplayers.dart';

class SoundService {
  final AudioPlayer _player = AudioPlayer();

  SoundService() {
    _init();
  }

  Future<void> _init() async {
    // Preload the sound cues
    await AudioCache.instance.loadAll([
      'audio/bell.mp3',
      'audio/wood.mp3',
      'audio/air.mp3',
      'audio/chime.mp3',
      'audio/tick.mp3',
    ]);
  }

  Future<void> playPhaseSound(String soundCue) async {
    // Stop any existing playback to ensure clean restart
    await _player.stop();
    // Use play() with the source explicitly to ensure it starts from the beginning every time
    await _player.play(AssetSource('audio/$soundCue.mp3'), volume: 0.3);
  }

  void dispose() {
    _player.dispose();
  }
}
