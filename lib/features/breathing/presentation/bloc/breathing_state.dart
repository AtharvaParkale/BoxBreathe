import 'package:equatable/equatable.dart';
import '../../domain/entities/breathing_mode.dart';

enum BreathingStatus { initial, active, paused, completed }

class BreathingState extends Equatable {
  final BreathingStatus status;
  final BreathingMode mode;
  final int sessionDurationMinutes; // Target duration
  final int sessionRemainingSeconds; // Countdown

  /// Post-session reward line shown for a few seconds on the completed
  /// screen. Reset to null on the next start/stop so stale text never
  /// leaks into a later session.
  final int? postSessionStreakDays;
  final String? postSessionAchievementTitle;

  const BreathingState({
    this.status = BreathingStatus.initial,
    this.mode = BreathingMode.box,
    this.sessionDurationMinutes = 3,
    this.sessionRemainingSeconds = 0,
    this.postSessionStreakDays,
    this.postSessionAchievementTitle,
  });

  static BreathingState initial() {
    return const BreathingState(sessionRemainingSeconds: 3 * 60);
  }

  BreathingState copyWith({
    BreathingStatus? status,
    BreathingMode? mode,
    int? sessionDurationMinutes,
    int? sessionRemainingSeconds,
    int? postSessionStreakDays,
    String? postSessionAchievementTitle,
    bool clearPostSessionReward = false,
  }) {
    return BreathingState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      sessionRemainingSeconds:
          sessionRemainingSeconds ?? this.sessionRemainingSeconds,
      postSessionStreakDays: clearPostSessionReward
          ? null
          : (postSessionStreakDays ?? this.postSessionStreakDays),
      postSessionAchievementTitle: clearPostSessionReward
          ? null
          : (postSessionAchievementTitle ?? this.postSessionAchievementTitle),
    );
  }

  @override
  List<Object?> get props => [
    status,
    mode,
    sessionDurationMinutes,
    sessionRemainingSeconds,
    postSessionStreakDays,
    postSessionAchievementTitle,
  ];
}
