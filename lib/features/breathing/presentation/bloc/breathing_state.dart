import 'package:equatable/equatable.dart';
import '../../domain/entities/breathing_mode.dart';

enum BreathingStatus { initial, active, paused, completed }

class BreathingState extends Equatable {
  final BreathingStatus status;
  final BreathingMode mode;
  final int sessionDurationMinutes; // Target duration
  final int sessionRemainingSeconds; // Countdown

  const BreathingState({
    this.status = BreathingStatus.initial,
    this.mode = BreathingMode.box,
    this.sessionDurationMinutes = 3,
    this.sessionRemainingSeconds = 0,
  });

  static BreathingState initial() {
    return const BreathingState(
      sessionRemainingSeconds: 3 * 60,
    );
  }


  BreathingState copyWith({
    BreathingStatus? status,
    BreathingMode? mode,
    int? sessionDurationMinutes,
    int? sessionRemainingSeconds,
  }) {
    return BreathingState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      sessionRemainingSeconds:
          sessionRemainingSeconds ?? this.sessionRemainingSeconds,
    );
  }

  @override
  List<Object> get props => [
        status,
        mode,
        sessionDurationMinutes,
        sessionRemainingSeconds,
      ];
}
