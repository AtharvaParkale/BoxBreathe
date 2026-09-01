import 'package:equatable/equatable.dart';
import 'package:flutter/animation.dart' show Curves;

enum BreathingPhaseKind { inhale, hold, exhale }

extension BreathingPhaseKindLabel on BreathingPhaseKind {
  String get displayLabel {
    switch (this) {
      case BreathingPhaseKind.inhale:
        return 'Inhale';
      case BreathingPhaseKind.hold:
        return 'Hold';
      case BreathingPhaseKind.exhale:
        return 'Exhale';
    }
  }
}

/// One segment of a breathing cycle: how long it lasts, what the orb scale
/// sweeps between, and what phase it counts as. Scale bounds are per-segment
/// (not inferred from [kind]) so a segment can represent a partial breath —
/// e.g. Physiological Sigh's second inhale only tops off the last bit of
/// the orb's scale range instead of sweeping a full breath.
class PhaseSegment extends Equatable {
  final BreathingPhaseKind kind;
  final int durationMs;
  final double scaleStart;
  final double scaleEnd;

  /// Overrides [BreathingPhaseKindLabel.displayLabel] for this segment,
  /// e.g. "AND AGAIN" for a second inhale.
  final String? labelOverride;

  const PhaseSegment({
    required this.kind,
    required this.durationMs,
    required this.scaleStart,
    required this.scaleEnd,
    this.labelOverride,
  });

  String get label => labelOverride ?? kind.displayLabel;

  @override
  List<Object?> get props => [kind, durationMs, scaleStart, scaleEnd, labelOverride];
}

/// The pure timing/animation shape of a breathing technique — an ordered
/// sequence of phase segments. Kept separate from `BreathingTechnique` so
/// multiple techniques can share one timing pattern under different
/// content (see BreathingTechniqueCatalog).
class BreathingPattern extends Equatable {
  final List<PhaseSegment> segments;

  const BreathingPattern(this.segments);

  int get cycleDurationMs => segments.fold(0, (sum, s) => sum + s.durationMs);

  /// Given [t] in `[0.0, 1.0]` (fraction of one full cycle), returns which
  /// segment is active, the orb scale within it, and its display label.
  ///
  /// Walks segments generically rather than assuming a fixed
  /// inhale/hold/exhale/hold shape — this is what lets techniques with a
  /// different phase count or order (e.g. Physiological Sigh's double
  /// inhale) drive the exact same orb animation code path.
  ({BreathingPhaseKind phase, double scale, String label}) phaseAt(double t) {
    final total = cycleDurationMs;
    if (segments.isEmpty || total == 0) {
      return (phase: BreathingPhaseKind.inhale, scale: 0.6, label: 'Inhale');
    }

    final tMs = t * total;
    double cursor = 0;
    for (final segment in segments) {
      final segEnd = cursor + segment.durationMs;
      if (tMs <= segEnd || segment == segments.last) {
        final localT = segment.durationMs == 0
            ? 1.0
            : ((tMs - cursor) / segment.durationMs).clamp(0.0, 1.0);
        final curve = segment.kind == BreathingPhaseKind.hold
            ? 1.0
            : Curves.easeInOut.transform(localT);
        final scale =
            segment.scaleStart + (segment.scaleEnd - segment.scaleStart) * curve;
        return (phase: segment.kind, scale: scale, label: segment.label);
      }
      cursor = segEnd;
    }
    final last = segments.last; // Unreachable in practice — safety fallback.
    return (phase: last.kind, scale: last.scaleEnd, label: last.label);
  }

  /// Builds the familiar inhale -> hold -> exhale -> hold shape as a
  /// segment list. A zero-duration hold is omitted rather than kept as a
  /// no-op segment, so e.g. Coherence (no holds) naturally becomes a
  /// 2-segment pattern instead of 4.
  factory BreathingPattern.classic({
    required int inhaleMs,
    required int holdAfterInhaleMs,
    required int exhaleMs,
    required int holdAfterExhaleMs,
  }) {
    return BreathingPattern([
      PhaseSegment(
        kind: BreathingPhaseKind.inhale,
        durationMs: inhaleMs,
        scaleStart: 0.6,
        scaleEnd: 1.0,
      ),
      if (holdAfterInhaleMs > 0)
        PhaseSegment(
          kind: BreathingPhaseKind.hold,
          durationMs: holdAfterInhaleMs,
          scaleStart: 1.0,
          scaleEnd: 1.0,
        ),
      PhaseSegment(
        kind: BreathingPhaseKind.exhale,
        durationMs: exhaleMs,
        scaleStart: 1.0,
        scaleEnd: 0.6,
      ),
      if (holdAfterExhaleMs > 0)
        PhaseSegment(
          kind: BreathingPhaseKind.hold,
          durationMs: holdAfterExhaleMs,
          scaleStart: 0.6,
          scaleEnd: 0.6,
        ),
    ]);
  }

  @override
  List<Object?> get props => [segments];
}
