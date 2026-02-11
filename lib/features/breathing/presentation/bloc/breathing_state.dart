import 'package:equatable/equatable.dart';
import '../../domain/entities/breathing_mode.dart';

enum BreathingStatus { initial, active, paused, completed }

class BreathingState extends Equatable {
  final BreathingStatus status;
  final BreathingMode mode;
  final BreathingPhase currentPhase;
  final int sessionDurationMinutes; // Target duration
  final int sessionRemainingSeconds; // Countdown
  final int phaseRemainingSeconds; // Phase countdown
  final String phaseLabel; // "Inhale", "Hold", etc.

  const BreathingState({
    this.status = BreathingStatus.initial,
    this.mode = BreathingMode.box,
    required this.currentPhase,
    this.sessionDurationMinutes = 3,
    this.sessionRemainingSeconds = 0,
    this.phaseRemainingSeconds = 0,
    this.phaseLabel = '',
  });

  static BreathingState initial() {
    return const BreathingState(
      currentPhase: BreathingPhase.inhale,
      sessionRemainingSeconds: 3 * 60,
      phaseRemainingSeconds: 4, // Start with Box mode Inhale
      phaseLabel: 'Inhale',
    );
  }


  BreathingState copyWith({
    BreathingStatus? status,
    BreathingMode? mode,
    BreathingPhase? currentPhase,
    int? sessionDurationMinutes,
    int? sessionRemainingSeconds,
    int? phaseRemainingSeconds,
    String? phaseLabel,
  }) {
    return BreathingState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      currentPhase: currentPhase ?? this.currentPhase,
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      sessionRemainingSeconds:
          sessionRemainingSeconds ?? this.sessionRemainingSeconds,
      phaseRemainingSeconds:
          phaseRemainingSeconds ?? this.phaseRemainingSeconds,
      phaseLabel: phaseLabel ?? this.phaseLabel,
    );
  }

  @override
  List<Object> get props => [
        status,
        mode,
        currentPhase,
        sessionDurationMinutes,
        sessionRemainingSeconds,
        phaseRemainingSeconds,
        phaseLabel
      ];
}
