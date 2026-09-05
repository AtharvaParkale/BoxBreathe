import 'package:equatable/equatable.dart';
import '../../domain/entities/breathing_technique.dart';
import '../../domain/entities/breathing_technique_catalog.dart';

enum BreathingStatus { initial, active, paused, completed }

class BreathingState extends Equatable {
  final BreathingStatus status;
  final BreathingTechnique technique;
  final int sessionDurationMinutes; // Target duration
  final int sessionRemainingSeconds; // Countdown

  /// Authoritative elapsed time within the current session, as computed by
  /// the timestamp-driven session engine — the only value the UI should
  /// ever use to re-anchor its animation, never something it derives
  /// itself. Reset to 0 on start/stop.
  final int sessionElapsedMs;

  /// True for exactly the one emission right after `ReconcileSession` found
  /// an in-progress (not finished) session — tells the UI to re-seed its
  /// animation controller from [sessionElapsedMs] instead of treating this
  /// like a normal tick. Always false otherwise; the page must not persist
  /// this flag itself, only react to it once.
  final bool justReconciled;

  /// The real, client-minted id of the in-progress session (set for
  /// active/paused, null otherwise) — the same id used for completion
  /// dedup/analytics. Exposed so the background-audio layer's Now Playing
  /// item identity actually matches the session it represents, instead of
  /// a synthetic placeholder.
  final String? activeSessionId;

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
    this.sessionElapsedMs = 0,
    this.justReconciled = false,
    this.activeSessionId,
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
    int? sessionElapsedMs,
    // Deliberately not nullable/preserved: `justReconciled` is a one-shot
    // signal for the single emission after a reconcile, so every other
    // emit must explicitly reset it rather than inheriting `true` forever.
    bool justReconciled = false,
    String? activeSessionId,
    bool clearActiveSessionId = false,
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
      sessionElapsedMs: sessionElapsedMs ?? this.sessionElapsedMs,
      justReconciled: justReconciled,
      activeSessionId: clearActiveSessionId
          ? null
          : (activeSessionId ?? this.activeSessionId),
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
    sessionElapsedMs,
    justReconciled,
    activeSessionId,
    selectedReason,
    postSessionStreakDays,
    postSessionAchievementTitle,
  ];
}
