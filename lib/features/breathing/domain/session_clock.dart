import 'package:equatable/equatable.dart';

/// A snapshot of an in-progress breathing session, entirely in terms of
/// wall-clock timestamps rather than a countdown counter. This is the
/// session's single source of truth: elapsed/remaining time and the current
/// breathing phase are always *derived* from it via [resolveSession], never
/// tracked as separate mutable state that could drift out of sync (e.g.
/// while the app is backgrounded and no `Timer`/`AnimationController` is
/// ticking).
class ActiveSessionSnapshot extends Equatable {
  final String sessionId;
  final String techniqueId;

  /// Target duration in minutes; -1 means an infinite session (never
  /// finishes on its own).
  final int sessionDurationMinutes;

  /// Why this technique was picked this time — carried through to
  /// completion analytics, see `BreathingState.selectedReason`.
  final String? selectedReason;

  final DateTime startedAt;

  /// Set while the session is paused (manual pause or an audio
  /// interruption); null while running. Time spent paused must never count
  /// toward elapsed session time.
  final DateTime? pausedAt;

  /// Total milliseconds already spent paused across any prior pause/resume
  /// cycles this session, excluded from elapsed-time math.
  final int accumulatedPauseMs;

  const ActiveSessionSnapshot({
    required this.sessionId,
    required this.techniqueId,
    required this.sessionDurationMinutes,
    required this.selectedReason,
    required this.startedAt,
    required this.pausedAt,
    required this.accumulatedPauseMs,
  });

  ActiveSessionSnapshot copyWith({
    DateTime? pausedAt,
    bool clearPausedAt = false,
    int? accumulatedPauseMs,
  }) {
    return ActiveSessionSnapshot(
      sessionId: sessionId,
      techniqueId: techniqueId,
      sessionDurationMinutes: sessionDurationMinutes,
      selectedReason: selectedReason,
      startedAt: startedAt,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      accumulatedPauseMs: accumulatedPauseMs ?? this.accumulatedPauseMs,
    );
  }

  @override
  List<Object?> get props => [
    sessionId,
    techniqueId,
    sessionDurationMinutes,
    selectedReason,
    startedAt,
    pausedAt,
    accumulatedPauseMs,
  ];
}

/// The result of resolving an [ActiveSessionSnapshot] against a point in
/// time — everything the UI/bloc need to display or act on, with no further
/// time math required at the call site.
class SessionResolution extends Equatable {
  /// Exact elapsed milliseconds (pause-excluded) — precise enough to
  /// re-anchor a phase animation without a visible jump, unlike
  /// [elapsedSeconds] which is rounded for display/countdown purposes.
  final int elapsedMs;
  final int elapsedSeconds;

  /// -1 for an infinite-duration session (never counts down).
  final int remainingSeconds;

  /// True once elapsed time has reached the target duration. Always false
  /// for an infinite-duration session.
  final bool isFinished;

  /// Fraction `[0.0, 1.0)` through the current breathing cycle — feed
  /// straight into `BreathingPattern.phaseAt`.
  final double cycleFraction;

  const SessionResolution({
    required this.elapsedMs,
    required this.elapsedSeconds,
    required this.remainingSeconds,
    required this.isFinished,
    required this.cycleFraction,
  });

  @override
  List<Object?> get props => [
    elapsedMs,
    elapsedSeconds,
    remainingSeconds,
    isFinished,
    cycleFraction,
  ];
}

/// Pure function: given a session snapshot, the active technique's cycle
/// length, and the current time, computes exactly where the session should
/// be. No I/O, no Flutter — this is what makes lock-screen/background
/// reconciliation correct instead of guessed: elapsed time is always
/// `now - startedAt`, minus any time spent paused, never a value that was
/// merely decremented while the app happened to be running.
SessionResolution resolveSession(
  ActiveSessionSnapshot snapshot,
  int cycleDurationMs,
  DateTime now,
) {
  final effectiveNow = snapshot.pausedAt ?? now;
  var elapsedMs =
      effectiveNow.difference(snapshot.startedAt).inMilliseconds -
      snapshot.accumulatedPauseMs;
  if (elapsedMs < 0) elapsedMs = 0;

  final elapsedSeconds = elapsedMs ~/ 1000;

  int remainingSeconds;
  bool isFinished;
  if (snapshot.sessionDurationMinutes == -1) {
    remainingSeconds = -1;
    isFinished = false;
  } else {
    final targetSeconds = snapshot.sessionDurationMinutes * 60;
    remainingSeconds = targetSeconds - elapsedSeconds;
    isFinished = remainingSeconds <= 0;
    if (remainingSeconds < 0) remainingSeconds = 0;
  }

  final cycleFraction = cycleDurationMs <= 0
      ? 0.0
      : (elapsedMs % cycleDurationMs) / cycleDurationMs;

  return SessionResolution(
    elapsedMs: elapsedMs,
    elapsedSeconds: elapsedSeconds,
    remainingSeconds: remainingSeconds,
    isFinished: isFinished,
    cycleFraction: cycleFraction,
  );
}
