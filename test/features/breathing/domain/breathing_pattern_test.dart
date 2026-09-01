import 'package:flutter/animation.dart' show Curves;
import 'package:flutter_test/flutter_test.dart';

import 'package:box_breathe/features/breathing/domain/entities/breathing_pattern.dart';

void main() {
  group('BreathingPattern.classic', () {
    test('omits zero-duration holds instead of keeping no-op segments', () {
      final coherence = BreathingPattern.classic(
        inhaleMs: 5500,
        holdAfterInhaleMs: 0,
        exhaleMs: 5500,
        holdAfterExhaleMs: 0,
      );
      expect(coherence.segments.length, 2);
      expect(coherence.segments.map((s) => s.kind), [
        BreathingPhaseKind.inhale,
        BreathingPhaseKind.exhale,
      ]);
      expect(coherence.cycleDurationMs, 11000);
    });

    test('keeps all 4 segments when both holds are non-zero (Box)', () {
      final box = BreathingPattern.classic(
        inhaleMs: 4000,
        holdAfterInhaleMs: 4000,
        exhaleMs: 4000,
        holdAfterExhaleMs: 4000,
      );
      expect(box.segments.map((s) => s.kind), [
        BreathingPhaseKind.inhale,
        BreathingPhaseKind.hold,
        BreathingPhaseKind.exhale,
        BreathingPhaseKind.hold,
      ]);
      expect(box.cycleDurationMs, 16000);
    });
  });

  group('BreathingPattern.phaseAt', () {
    // Golden-value regression: the old engine (pre-generalization) computed
    // phase boundaries as `inhaleEnd = inhale/total`,
    // `holdFullEnd = inhaleEnd + hold1/total`, `exhaleEnd = holdFullEnd +
    // exhale/total`, with scale `0.6 + 0.4*curve` on inhale and
    // `1.0 - 0.4*curve` on exhale, flat 1.0/0.6 on holds. This test proves
    // the segment-based engine reproduces those exact boundaries and
    // scales for Box (the one existing pattern that exercises all 4
    // phases), so the generalization is provably a non-regression.
    test('Box: phase boundaries and scale match the pre-generalization engine', () {
      final box = BreathingPattern.classic(
        inhaleMs: 4000,
        holdAfterInhaleMs: 4000,
        exhaleMs: 4000,
        holdAfterExhaleMs: 4000,
      );

      // Just inside inhale (0 - 0.25)
      var result = box.phaseAt(0.1);
      expect(result.phase, BreathingPhaseKind.inhale);
      expect(result.scale, closeTo(0.6 + 0.4 * Curves.easeInOut.transform(0.4), 1e-9));

      // Exactly at the inhale/hold boundary: `<=` favors the earlier
      // segment, same as the pre-generalization engine did — inhale ends
      // "full" (scale 1.0) rather than hold starting.
      result = box.phaseAt(0.25);
      expect(result.phase, BreathingPhaseKind.inhale);
      expect(result.scale, 1.0);

      // Just past the boundary: now inside the hold.
      result = box.phaseAt(0.2501);
      expect(result.phase, BreathingPhaseKind.hold);
      expect(result.scale, 1.0);

      // Mid hold-after-inhale (0.25 - 0.5)
      result = box.phaseAt(0.375);
      expect(result.phase, BreathingPhaseKind.hold);
      expect(result.scale, 1.0);

      // Mid exhale (0.5 - 0.75)
      result = box.phaseAt(0.625);
      expect(result.phase, BreathingPhaseKind.exhale);
      expect(result.scale, closeTo(1.0 - 0.4 * Curves.easeInOut.transform(0.5), 1e-9));

      // Hold-after-exhale (0.75 - 1.0)
      result = box.phaseAt(0.9);
      expect(result.phase, BreathingPhaseKind.hold);
      expect(result.scale, 0.6);
    });

    test('Coherence: no-hold pattern only ever reports inhale/exhale', () {
      final coherence = BreathingPattern.classic(
        inhaleMs: 5500,
        holdAfterInhaleMs: 0,
        exhaleMs: 5500,
        holdAfterExhaleMs: 0,
      );
      for (final t in [0.0, 0.1, 0.25, 0.49, 0.51, 0.75, 0.99]) {
        final phase = coherence.phaseAt(t).phase;
        expect(
          phase == BreathingPhaseKind.inhale || phase == BreathingPhaseKind.exhale,
          isTrue,
          reason: 'unexpected phase $phase at t=$t',
        );
      }
    });

    test(
      'Physiological Sigh: reports a labeled second inhale, not a hold',
      () {
        final sigh = BreathingPattern([
          const PhaseSegment(
            kind: BreathingPhaseKind.inhale,
            durationMs: 2000,
            scaleStart: 0.6,
            scaleEnd: 0.85,
          ),
          const PhaseSegment(
            kind: BreathingPhaseKind.inhale,
            durationMs: 1000,
            scaleStart: 0.85,
            scaleEnd: 1.0,
            labelOverride: 'AND AGAIN',
          ),
          const PhaseSegment(
            kind: BreathingPhaseKind.exhale,
            durationMs: 6000,
            scaleStart: 1.0,
            scaleEnd: 0.6,
          ),
        ]);

        // Well inside the second inhale segment (2000-3000ms of a 9000ms
        // cycle).
        final result = sigh.phaseAt(2500 / 9000);
        expect(result.phase, BreathingPhaseKind.inhale);
        expect(result.label, 'AND AGAIN');
        expect(result.scale, greaterThan(0.85));
        expect(result.scale, lessThanOrEqualTo(1.0));
      },
    );

    test('empty pattern falls back to a safe default instead of crashing', () {
      final result = const BreathingPattern([]).phaseAt(0.5);
      expect(result.phase, BreathingPhaseKind.inhale);
      expect(result.scale, 0.6);
    });
  });
}
