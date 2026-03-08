import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static const _soundCues = [
    'bell', 'wood', 'air', 'chime', 'tick',
    'bowl', 'gong', 'crystal', 'rain', 'ocean',
  ];

  // One dedicated player per sound — no stop→play cycle between cues
  final Map<String, AudioPlayer> _players = {};

  // Stored Future so any concurrent playPhaseSound call awaits the same init
  late final Future<void> _initialized;

  SoundService() {
    _initialized = _init();
  }

  Future<void> _init() async {
    // Pre-populate AudioCache so file I/O never happens at play time
    await AudioCache.instance.loadAll([
      'audio/bell.mp3',
      'audio/wood.mp3',
      'audio/air.mp3',
      'audio/chime.mp3',
      'audio/tick.mp3',
      'audio/bowl.mp3',
      'audio/gong.mp3',
      'audio/crystal.mp3',
      'audio/rain.mp3',
      'audio/ocean.mp3',
    ]);

    for (final cue in _soundCues) {
      _players[cue] = AudioPlayer();
    }
  }

  Future<void> playPhaseSound(String soundCue) async {
    await _initialized;

    final player = _players[soundCue];
    if (player == null) return;

    // play() always works regardless of player state, and AudioCache ensures
    // the asset is already in memory so there's no file-load latency.
    // With dedicated players there's no cross-cue stop() — lag issue is gone.
    await player.play(AssetSource('audio/$soundCue.mp3'), volume: 0.8);
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }
}
