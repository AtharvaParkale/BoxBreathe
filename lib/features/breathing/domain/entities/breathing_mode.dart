import 'package:equatable/equatable.dart';

enum BreathingPhase {
  inhale,
  holdFull, // Hold after inhale
  exhale,
  holdEmpty, // Hold after exhale
}

class BreathingMode extends Equatable {
  final String name;
  final int inhaleDurationMs;
  final int holdFullDurationMs;
  final int exhaleDurationMs;
  final int holdEmptyDurationMs;

  const BreathingMode({
    required this.name,
    required this.inhaleDurationMs,
    required this.holdFullDurationMs,
    required this.exhaleDurationMs,
    required this.holdEmptyDurationMs,
  });

  int get cycleDurationMs =>
      inhaleDurationMs +
      holdFullDurationMs +
      exhaleDurationMs +
      holdEmptyDurationMs;

  @override
  List<Object?> get props => [
        name,
        inhaleDurationMs,
        holdFullDurationMs,
        exhaleDurationMs,
        holdEmptyDurationMs,
      ];

  static const box = BreathingMode(
    name: 'Box',
    inhaleDurationMs: 4000,
    holdFullDurationMs: 4000,
    exhaleDurationMs: 4000,
    holdEmptyDurationMs: 4000,
  );

  static const calm = BreathingMode(
    name: 'Calm',
    inhaleDurationMs: 4000,
    holdFullDurationMs: 7000,
    exhaleDurationMs: 8000,
    holdEmptyDurationMs: 0,
  );

  static const quickReset = BreathingMode(
    name: 'Quick Reset',
    inhaleDurationMs: 3000,
    holdFullDurationMs: 3000,
    exhaleDurationMs: 3000,
    holdEmptyDurationMs: 3000,
  );

  static const sleep = BreathingMode(
    name: 'Sleep',
    inhaleDurationMs: 5000,
    holdFullDurationMs: 5000,
    exhaleDurationMs: 7000,
    holdEmptyDurationMs: 0,
  );

  static const wimHof = BreathingMode(
    name: 'Wim Hof',
    inhaleDurationMs: 1500,
    holdFullDurationMs: 0,
    exhaleDurationMs: 1500,
    holdEmptyDurationMs: 0,
  );

  static const deepBreathing = BreathingMode(
    name: 'Deep Breathing',
    inhaleDurationMs: 5000,
    holdFullDurationMs: 0,
    exhaleDurationMs: 5000,
    holdEmptyDurationMs: 0,
  );

  static const relaxedHold = BreathingMode(
    name: 'Relaxed Hold',
    inhaleDurationMs: 4000,
    holdFullDurationMs: 6000,
    exhaleDurationMs: 6000,
    holdEmptyDurationMs: 0,
  );

  static const quickBreathing = BreathingMode(
    name: 'Quick Breathing',
    inhaleDurationMs: 2000,
    holdFullDurationMs: 0,
    exhaleDurationMs: 2000,
    holdEmptyDurationMs: 0,
  );

  static const equalBreathing = BreathingMode(
    name: 'Equal Breathing',
    inhaleDurationMs: 4000,
    holdFullDurationMs: 0,
    exhaleDurationMs: 4000,
    holdEmptyDurationMs: 0,
  );

  static const coherence = BreathingMode(
    name: 'Coherence',
    inhaleDurationMs: 5500,
    holdFullDurationMs: 0,
    exhaleDurationMs: 5500,
    holdEmptyDurationMs: 0,
  );

  static const pursedLip = BreathingMode(
    name: 'Pursed Lip',
    inhaleDurationMs: 2000,
    holdFullDurationMs: 0,
    exhaleDurationMs: 4000,
    holdEmptyDurationMs: 0,
  );

  static const sevenEleven = BreathingMode(
    name: '7-11 Relax',
    inhaleDurationMs: 7000,
    holdFullDurationMs: 0,
    exhaleDurationMs: 11000,
    holdEmptyDurationMs: 0,
  );

  static const triangular = BreathingMode(
    name: 'Triangular',
    inhaleDurationMs: 4000,
    holdFullDurationMs: 4000,
    exhaleDurationMs: 4000,
    holdEmptyDurationMs: 0,
  );

  static const List<BreathingMode> values = [
    box,
    calm,
    quickReset,
    sleep,
    wimHof,
    deepBreathing,
    relaxedHold,
    quickBreathing,
    equalBreathing,
    coherence,
    pursedLip,
    sevenEleven,
    triangular,
  ];
}
