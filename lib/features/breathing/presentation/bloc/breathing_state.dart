import 'package:equatable/equatable.dart';
import '../../domain/entities/breathing_technique.dart';
import '../../domain/entities/breathing_technique_catalog.dart';

enum BreathingStatus { initial, active, paused, completed }

class BreathingState extends Equatable {
  final BreathingStatus status;
  final BreathingTechnique technique;
  final int sessionDurationMinutes; // Target duration
  final int sessionRemainingSeconds; // Countdown

  /// Why the current technique was picked this time (e.g. 'calm', 'sleep')
  /// — set by need-based entry points (moment picker, quick relief), null
  /// when a technique is chosen directly. Used for session analytics.
  final String? selectedReason;

  /// Post-session reward line shown for a few seconds on the completed
  /// screen. Reset to null on the next start/stop so stale text never
  /// leaks into a later session.
  final int? postSessionStreakDays;
  final String? postSessionAchievementTitle;

  BreathingState({
    this.status = BreathingStatus.initial,
    BreathingTechnique? technique,
    this.sessionDurationMinutes = 3,
    this.sessionRemainingSeconds = 0,
    this.selectedReason,
    this.postSessionStreakDays,
    this.postSessionAchievementTitle,
  }) : technique = technique ?? BreathingTechniqueCatalog.defaultTechnique;

  static BreathingState initial() {
    return BreathingState(sessionRemainingSeconds: 3 * 60);
  }

  BreathingState copyWith({
    BreathingStatus? status,
    BreathingTechnique? technique,
    int? sessionDurationMinutes,
    int? sessionRemainingSeconds,
    String? selectedReason,
    bool clearSelectedReason = false,
    int? postSessionStreakDays,
    String? postSessionAchievementTitle,
    bool clearPostSessionReward = false,
  }) {
    return BreathingState(
      status: status ?? this.status,
      technique: technique ?? this.technique,
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      sessionRemainingSeconds:
          sessionRemainingSeconds ?? this.sessionRemainingSeconds,
      selectedReason: clearSelectedReason
          ? null
          : (selectedReason ?? this.selectedReason),
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
    technique,
    sessionDurationMinutes,
    sessionRemainingSeconds,
    selectedReason,
    postSessionStreakDays,
    postSessionAchievementTitle,
  ];
}
