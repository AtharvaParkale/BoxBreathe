import 'package:equatable/equatable.dart';

enum BreathingPhase {
  inhale,
  holdFull, // Hold after inhale
  exhale,
  holdEmpty, // Hold after exhale
}

class BreathingMode extends Equatable {
  final String name;
  final int inhaleDuration;
  final int holdFullDuration;
  final int exhaleDuration;
  final int holdEmptyDuration;

  const BreathingMode({
    required this.name,
    required this.inhaleDuration,
    required this.holdFullDuration,
    required this.exhaleDuration,
    required this.holdEmptyDuration,
  });

  int get cycleDuration =>
      inhaleDuration + holdFullDuration + exhaleDuration + holdEmptyDuration;

  @override
  List<Object?> get props => [
        name,
        inhaleDuration,
        holdFullDuration,
        exhaleDuration,
        holdEmptyDuration
      ];

  static const box = BreathingMode(
    name: 'Box',
    inhaleDuration: 4,
    holdFullDuration: 4,
    exhaleDuration: 4,
    holdEmptyDuration: 4,
  );

  static const calm = BreathingMode(
    name: 'Calm',
    inhaleDuration: 4,
    holdFullDuration: 7,
    exhaleDuration: 8,
    holdEmptyDuration: 0,
  );

  static const quickReset = BreathingMode(
    name: 'Quick Reset',
    inhaleDuration: 3,
    holdFullDuration: 3,
    exhaleDuration: 3,
    holdEmptyDuration: 3,
  );

  static const sleep = BreathingMode(
    name: 'Sleep',
    inhaleDuration: 5,
    holdFullDuration: 5,
    exhaleDuration: 7,
    holdEmptyDuration: 0,
  );

  static const List<BreathingMode> values = [
    box,
    calm,
    quickReset,
    sleep,
  ];
}
