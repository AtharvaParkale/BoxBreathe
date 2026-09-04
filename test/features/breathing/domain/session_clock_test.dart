import 'package:flutter_test/flutter_test.dart';

import 'package:box_breathe/features/breathing/domain/session_clock.dart';

void main() {
  final start = DateTime(2026, 1, 1, 12, 0, 0);

  ActiveSessionSnapshot snapshot({
    int sessionDurationMinutes = 3,
    DateTime? pausedAt,
    int accumulatedPauseMs = 0,
  }) {
    return ActiveSessionSnapshot(
      sessionId: 'session-1',
      techniqueId: 'box',
      sessionDurationMinutes: sessionDurationMinutes,
      selectedReason: null,
      startedAt: start,
      pausedAt: pausedAt,
      accumulatedPauseMs: accumulatedPauseMs,
    );
  }

  group('resolveSession — elapsed/remaining', () {
    test('computes remaining time purely from elapsed wall-clock time', () {
      final resolution = resolveSession(
        snapshot(sessionDurationMinutes: 3),
        4000,
        start.add(const Duration(seconds: 45)),
      );
      expect(resolution.elapsedSeconds, 45);
      expect(resolution.remainingSeconds, 180 - 45);
      expect(resolution.isFinished, isFalse);
    });

    test('is finished exactly when elapsed reaches the target duration', () {
      final atBoundary = resolveSession(
        snapshot(sessionDurationMinutes: 3),
        4000,
        start.add(const Duration(minutes: 3)),
      );
      expect(atBoundary.remainingSeconds, 0);
      expect(atBoundary.isFinished, isTrue);
    });

    test('remaining never goes negative once finished (e.g. finished '
        'while backgrounded, discovered much later)', () {
      final wayLater = resolveSession(
        snapshot(sessionDurationMinutes: 3),
        4000,
        start.add(const Duration(hours: 2)),
      );
      expect(wayLater.remainingSeconds, 0);
      expect(wayLater.isFinished, isTrue);
    });

    test('an infinite-duration session (-1) never finishes', () {
      final resolution = resolveSession(
        snapshot(sessionDurationMinutes: -1),
        4000,
        start.add(const Duration(days: 1)),
      );
      expect(resolution.remainingSeconds, -1);
      expect(resolution.isFinished, isFalse);
    });
  });

  group('resolveSession — pausing', () {
    test('elapsed time freezes while paused', () {
      final pausedAt = start.add(const Duration(seconds: 10));
      final resolution = resolveSession(
        snapshot(pausedAt: pausedAt),
        4000,
        // "now" is much later, but the session is paused — elapsed must
        // reflect only up to the moment it was paused.
        start.add(const Duration(minutes: 5)),
      );
      expect(resolution.elapsedSeconds, 10);
    });

    test('accumulated pause time is excluded once resumed', () {
      // Paused for 20s starting at t=10s, then resumed; "now" is t=40s.
      final resolution = resolveSession(
        snapshot(accumulatedPauseMs: 20000),
        4000,
        start.add(const Duration(seconds: 40)),
      );
      // 40s of wall-clock time minus 20s spent paused = 20s of real elapsed.
      expect(resolution.elapsedSeconds, 20);
    });
  });

  group('resolveSession — cycleFraction', () {
    test('wraps correctly across multiple completed cycles', () {
      // 4000ms cycle, 10.5s elapsed => 2 full cycles (8000ms) + 2500ms into
      // the third => 2500/4000 = 0.625.
      final resolution = resolveSession(
        snapshot(sessionDurationMinutes: -1),
        4000,
        start.add(const Duration(milliseconds: 10500)),
      );
      expect(resolution.cycleFraction, closeTo(0.625, 0.0001));
    });

    test('is 0.0 for a degenerate zero-length cycle', () {
      final resolution = resolveSession(snapshot(), 0, start);
      expect(resolution.cycleFraction, 0.0);
    });
  });
}
