import 'package:box_breathe/features/progress/domain/entities/achievement_definition.dart';
import 'package:box_breathe/features/progress/domain/entities/achievement_progress.dart';
import 'package:box_breathe/features/progress/domain/entities/progress_session_record.dart';
import 'package:box_breathe/features/progress/domain/entities/progress_summary.dart';
import 'package:box_breathe/features/progress/domain/entities/streak_info.dart';

List<AchievementProgress> _achievements({required bool someUnlocked}) => [
  AchievementProgress(
    definition: AchievementDefinition.firstSession,
    current: someUnlocked ? 1 : 0,
    unlocked: someUnlocked,
    unlockedAt: someUnlocked
        ? DateTime.now().subtract(const Duration(days: 6))
        : null,
  ),
  AchievementProgress(
    definition: AchievementDefinition.sessions10,
    current: someUnlocked ? 9 : 0,
    unlocked: false,
    unlockedAt: null,
  ),
  const AchievementProgress(
    definition: AchievementDefinition.sessions50,
    current: 9,
    unlocked: false,
    unlockedAt: null,
  ),
];

ProgressSummary emptySummary() => ProgressSummary(
  streak: StreakInfo.empty,
  lifetime: LifetimeStats.empty,
  thisWeek: WeekSummary.empty,
  monthlyPracticeCounts: const {},
  byTechnique: const [],
  personalRecords: PersonalRecords.empty,
  achievements: _achievements(someUnlocked: false),
);

ProgressSummary fullSummary() => ProgressSummary(
  streak: const StreakInfo(
    current: 5,
    longest: 8,
    lastPracticedDateKey: '2026-10-15',
    isActiveToday: true,
  ),
  lifetime: const LifetimeStats(
    totalSessions: 9,
    totalMinutes: 64,
    totalDaysPracticed: 7,
  ),
  thisWeek: const WeekSummary(
    sessionsThisWeek: 4,
    minutesThisWeek: 22,
    perDayPracticed: [true, true, false, true, true, false, false],
  ),
  monthlyPracticeCounts: const {1: 1, 2: 2, 5: 1, 9: 1, 10: 1, 12: 2, 13: 1},
  byTechnique: const [
    TechniqueBreakdownEntry(
      techniqueId: 'box',
      techniqueName: 'Box Breathing',
      sessionCount: 5,
      totalMinutes: 30,
      percentage: 0.55,
    ),
    TechniqueBreakdownEntry(
      techniqueId: 'calm478',
      techniqueName: '4-7-8 Breathing',
      sessionCount: 4,
      totalMinutes: 34,
      percentage: 0.45,
    ),
  ],
  personalRecords: const PersonalRecords(
    longestStreakDays: 8,
    longestSessionMinutes: 10,
    mostSessionsInOneDay: 2,
    totalDaysPracticed: 7,
  ),
  achievements: _achievements(someUnlocked: true),
);

List<ProgressSessionRecord> recentRecords() {
  final now = DateTime.now();
  ProgressSessionRecord r(
    String id,
    String technique,
    String name,
    int days,
    int minutes,
  ) {
    final at = now.subtract(Duration(days: days, hours: 1));
    return ProgressSessionRecord(
      id: id,
      techniqueId: technique,
      techniqueName: name,
      completedDurationSeconds: minutes * 60,
      startedAt: at.subtract(Duration(minutes: minutes)),
      completedAt: at,
      dateKeyLocal: '${at.year}-${at.month}-${at.day}',
    );
  }

  return [
    r('a', 'box', 'Box Breathing', 0, 4),
    r('b', 'calm478', '4-7-8 Breathing', 1, 5),
    r('c', 'coherence', 'Coherent Breathing', 3, 10),
  ];
}
