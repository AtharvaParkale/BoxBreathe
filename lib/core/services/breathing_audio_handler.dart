import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart' as ap;

/// Owns the real background-audio session (`AVAudioSession` on iOS, the
/// media-session foreground service on Android, both managed by
/// `audio_service`) and the Now Playing / lock-screen card for an
/// in-progress breathing session.
///
/// Only ever started when the user has sound cues enabled — the continuous
/// low-volume loop played here *is* the user's own selected ambience cue,
/// simply held on for the session's duration instead of only firing in
/// short bursts. That continuous, real audio output is what genuinely
/// justifies holding `UIBackgroundModes: audio` / the Android foreground
/// service open for the session — this is not a keep-alive trick layered on
/// top of an unrelated feature.
///
/// Position is pushed once per discontinuity (start/pause/resume/reconcile),
/// not every second — `audio_service` extrapolates the live countdown shown
/// on the lock screen from `updatePosition` + `updateTime` + `speed`.
class BreathingAudioHandler extends BaseAudioHandler {
  final ap.AudioPlayer _player = ap.AudioPlayer();
  final _interruptionController = StreamController<void>.broadcast();

  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  StreamSubscription<void>? _becomingNoisySub;

  /// Fires when playback should pause due to a genuine interruption
  /// (incoming call, another app taking audio focus) or a route change
  /// (headphones/Bluetooth disconnect). Listeners should treat this exactly
  /// like a user-initiated pause. Deliberately does *not* auto-resume when
  /// an interruption ends — leaving the session paused is the safer,
  /// graceful-failure choice (e.g. don't silently continue after a call).
  Stream<void> get onInterruption => _interruptionController.stream;

  BreathingAudioHandler() {
    unawaited(_configureSession());
  }

  Future<void> _configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _interruptionSub = session.interruptionEventStream.listen((event) {
      if (event.begin) _interruptionController.add(null);
    });
    _becomingNoisySub = session.becomingNoisyEventStream.listen((_) {
      _interruptionController.add(null);
    });
  }

  Future<void> startSession({
    required String sessionId,
    required String techniqueName,
    required int sessionDurationMinutes,
    required String ambienceCue,
    required Duration elapsed,
  }) async {
    mediaItem.add(
      MediaItem(
        id: sessionId,
        title: 'Ease',
        artist: 'Breathing · $techniqueName',
        duration: sessionDurationMinutes == -1
            ? null
            : Duration(minutes: sessionDurationMinutes),
      ),
    );
    await _player.setReleaseMode(ap.ReleaseMode.loop);
    await _player.play(ap.AssetSource('audio/$ambienceCue.mp3'), volume: 0.12);
    _publish(elapsed: elapsed, playing: true);
  }

  Future<void> pauseSession(Duration elapsed) async {
    await _player.pause();
    _publish(elapsed: elapsed, playing: false);
  }

  Future<void> resumeSession(Duration elapsed) async {
    await _player.resume();
    _publish(elapsed: elapsed, playing: true);
  }

  Future<void> endSession() async {
    await _player.stop();
    playbackState.add(
      PlaybackState(
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
  }

  void _publish({required Duration elapsed, required bool playing}) {
    playbackState.add(
      PlaybackState(
        controls: [MediaControl.stop],
        processingState: AudioProcessingState.ready,
        playing: playing,
        updatePosition: elapsed,
        updateTime: DateTime.now(),
        speed: playing ? 1.0 : 0.0,
      ),
    );
  }

  @override
  Future<void> stop() async {
    await endSession();
    await super.stop();
  }

  Future<void> dispose() async {
    await _interruptionSub?.cancel();
    await _becomingNoisySub?.cancel();
    await _interruptionController.close();
    await _player.dispose();
  }
}
