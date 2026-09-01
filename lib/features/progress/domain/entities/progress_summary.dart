import 'package:equatable/equatable.dart';

import 'achievement_progress.dart';
import 'streak_info.dart';

class LifetimeStats extends Equatable {
  final int totalSessions;
  final int totalMinutes;
  final int totalDaysPracticed;

  const LifetimeStats({
    required this.totalSessions,
    required this.totalMinutes,
    required this.totalDaysPracticed,
  });

  static const empty = LifetimeStats(
    totalSessions: 0,
    totalMinutes: 0,
    totalDaysPracticed: 0,
  );

  @override
  List<Object?> get props => [totalSessions, totalMinutes, totalDaysPracticed];
}

class WeekSummary extends Equatable {
  final int sessionsThisWeek;
  final int minutesThisWeek;

  /// Monday..Sunday, true where at least one session was completed.
  final List<bool> perDayPracticed;

  const WeekSummary({
    required this.sessionsThisWeek,
    required this.minutesThisWeek,
    required this.perDayPracticed,
  });

  static const empty = WeekSummary(
    sessionsThisWeek: 0,
    minutesThisWeek: 0,
    perDayPracticed: [false, false, false, false, false, false, false],
  );

  @override
  List<Object?> get props => [sessionsThisWeek, minutesThisWeek, perDayPracticed];
}

class TechniqueBreakdownEntry extends Equatable {
  final String techniqueId;
  final String techniqueName;
  final int sessionCount;
  final int totalMinutes;
  final double percentage;

  const TechniqueBreakdownEntry({
    required this.techniqueId,
    required this.techniqueName,
    required this.sessionCount,
    required this.totalMinutes,
    required this.percentage,
  });

  @override
  List<Object?> get props => [
    techniqueId,
    techniqueName,
    sessionCount,
    totalMinutes,
    percentage,
  ];
}

class PersonalRecords extends Equatable {
  final int longestStreakDays;
  final int longestSessionMinutes;
  final int mostSessionsInOneDay;
  final int totalDaysPracticed;

  const PersonalRecords({
    required this.longestStreakDays,
    required this.longestSessionMinutes,
    required this.mostSessionsInOneDay,
    required this.totalDaysPracticed,
  });

  static const empty = PersonalRecords(
    longestStreakDays: 0,
    longestSessionMinutes: 0,
    mostSessionsInOneDay: 0,
    totalDaysPracticed: 0,
  );

  @override
  List<Object?> get props => [
    longestStreakDays,
    longestSessionMinutes,
    mostSessionsInOneDay,
    totalDaysPracticed,
  ];
}

/// The single screen-level aggregate the Progress page renders. Everything
/// but the raw session records and achievement-unlock timestamps is
/// computed on the fly from the local session set — no separate aggregate
/// counters to keep in sync, no drift possible.
class ProgressSummary extends Equatable {
  final StreakInfo streak;
  final LifetimeStats lifetime;
  final WeekSummary thisWeek;

  /// Day-of-month -> session count, for the currently displayed month.
  final Map<int, int> monthlyPracticeCounts;
  final List<TechniqueBreakdownEntry> byTechnique;
  final PersonalRecords personalRecords;
  final List<AchievementProgress> achievements;

  const ProgressSummary({
    required this.streak,
    required this.lifetime,
    required this.thisWeek,
    required this.monthlyPracticeCounts,
    required this.byTechnique,
    required this.personalRecords,
    required this.achievements,
  });

  @override
  List<Object?> get props => [
    streak,
    lifetime,
    thisWeek,
    monthlyPracticeCounts,
    byTechnique,
    personalRecords,
    achievements,
  ];
}
