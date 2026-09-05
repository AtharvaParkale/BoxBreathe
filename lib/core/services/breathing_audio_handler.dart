import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';

/// Owns the real background-audio session (`AVAudioSession` on iOS, the
/// media-session foreground service on Android, both managed by
/// `audio_service`) and the Now Playing / lock-screen card for an
/// in-progress breathing session.
///
/// Only ever engaged when the user has sound cues enabled. This handler
/// deliberately does **not** play its own audio track: the app's existing
/// per-phase cue sounds (`SoundService`, fired on every breathing phase
/// change via the same `audio_session`-configured category) are the real,
/// periodic audio output that justifies holding `UIBackgroundModes: audio` /
/// the Android foreground service open for the session. This handler's job
/// is solely to configure that shared audio session category and publish
/// Now Playing info from real elapsed time — an earlier version looped one
/// of the short one-shot phase-cue clips as a fake "ambience" track, which
/// produced an audible rapid-fire clicking loop for short cues (tick/bell/
/// chime) instead of anything resembling ambience.
///
/// Position is pushed once per discontinuity (start/pause/resume/reconcile),
/// not every second — `audio_service` extrapolates the live countdown shown
/// on the lock screen from `updatePosition` + `updateTime` + `speed`.
class BreathingAudioHandler extends BaseAudioHandler {
  final _interruptionController = StreamController<void>.broadcast();

  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  StreamSubscription<void>? _becomingNoisySub;
  Future<void>? _configured;

  /// Fires when playback should pause due to a genuine interruption
  /// (incoming call, another app taking audio focus) or a route change
  /// (headphones/Bluetooth disconnect). Listeners should treat this exactly
  /// like a user-initiated pause. Deliberately does *not* auto-resume when
  /// an interruption ends — leaving the session paused is the safer,
  /// graceful-failure choice (e.g. don't silently continue after a call).
  Stream<void> get onInterruption => _interruptionController.stream;

  /// Completes once the platform audio session category has actually been
  /// configured and interruption listeners are attached. Callers should
  /// await this once at startup before trusting background/interruption
  /// handling to be live.
  Future<void> get ready => _configured ??= _configureSession();

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
    _publish(elapsed: elapsed, playing: true);
  }

  Future<void> pauseSession(Duration elapsed) async {
    _publish(elapsed: elapsed, playing: false);
  }

  Future<void> resumeSession(Duration elapsed) async {
    _publish(elapsed: elapsed, playing: true);
  }

  Future<void> endSession() async {
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
  }
}
