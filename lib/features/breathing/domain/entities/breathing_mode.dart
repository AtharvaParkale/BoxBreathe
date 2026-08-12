import 'package:equatable/equatable.dart';

enum BreathingPhase {
  inhale,
  holdFull, // Hold after inhale
  exhale,
  holdEmpty, // Hold after exhale
}

extension BreathingPhaseLabel on BreathingPhase {
  String get displayLabel {
    switch (this) {
      case BreathingPhase.inhale:
        return 'Inhale';
      case BreathingPhase.holdFull:
      case BreathingPhase.holdEmpty:
        return 'Hold';
      case BreathingPhase.exhale:
        return 'Exhale';
    }
  }
}

class BreathingMode extends Equatable {
  // Stable identifier used for persistence. Independent of [name] so the
  // display label can change without breaking saved user preferences.
  final String id;
  final String name;
  final int inhaleDurationMs;
  final int holdFullDurationMs;
  final int exhaleDurationMs;
  final int holdEmptyDurationMs;

  const BreathingMode({
    required this.id,
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
    id,
    name,
    inhaleDurationMs,
    holdFullDurationMs,
    exhaleDurationMs,
    holdEmptyDurationMs,
  ];

  static const box = BreathingMode(
    id: 'box',
    name: 'Box',
    inhaleDurationMs: 4000,
    holdFullDurationMs: 4000,
    exhaleDurationMs: 4000,
    holdEmptyDurationMs: 4000,
  );

  static const calm = BreathingMode(
    id: 'calm478',
    name: '4-7-8',
    inhaleDurationMs: 4000,
    holdFullDurationMs: 7000,
    exhaleDurationMs: 8000,
    holdEmptyDurationMs: 0,
  );

  static const sleep = BreathingMode(
    id: 'sleep',
    name: 'Sleep',
    inhaleDurationMs: 5000,
    holdFullDurationMs: 5000,
    exhaleDurationMs: 7000,
    holdEmptyDurationMs: 0,
  );

  static const coherence = BreathingMode(
    id: 'coherence',
    name: 'Coherence',
    inhaleDurationMs: 5500,
    holdFullDurationMs: 0,
    exhaleDurationMs: 5500,
    holdEmptyDurationMs: 0,
  );

  static const quickReset = BreathingMode(
    id: 'quickReset',
    name: 'Quick Reset',
    inhaleDurationMs: 3000,
    holdFullDurationMs: 3000,
    exhaleDurationMs: 3000,
    holdEmptyDurationMs: 3000,
  );

  static const List<BreathingMode> values = [
    box,
    calm,
    sleep,
    coherence,
    quickReset,
  ];
}
