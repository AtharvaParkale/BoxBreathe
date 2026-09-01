import 'package:equatable/equatable.dart';

enum AchievementRequirementType {
  totalSessions,
  totalMinutes,
  distinctDaysPracticed,
  streakDays,
  techniqueVariety,
}

/// Static, curated achievement catalog — mirrors the `BreathingMode.values`
/// pattern already used elsewhere in this codebase. Deliberately small
/// (12 entries): no time-of-day achievements, no numeric badge inflation.
class AchievementDefinition extends Equatable {
  final String id;
  final String title;
  final String description;
  final AchievementRequirementType type;
  final num threshold;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.threshold,
  });

  @override
  List<Object?> get props => [id, title, description, type, threshold];

  static const firstSession = AchievementDefinition(
    id: 'first_session',
    title: 'First Breath',
    description: 'Complete your first session.',
    type: AchievementRequirementType.totalSessions,
    threshold: 1,
  );

  static const sessions10 = AchievementDefinition(
    id: 'sessions_10',
    title: 'Ten Sessions',
    description: 'Complete 10 sessions.',
    type: AchievementRequirementType.totalSessions,
    threshold: 10,
  );

  static const sessions50 = AchievementDefinition(
    id: 'sessions_50',
    title: 'Fifty Sessions',
    description: 'Complete 50 sessions.',
    type: AchievementRequirementType.totalSessions,
    threshold: 50,
  );

  static const sessions100 = AchievementDefinition(
    id: 'sessions_100',
    title: 'A Hundred Sessions',
    description: 'Complete 100 sessions.',
    type: AchievementRequirementType.totalSessions,
    threshold: 100,
  );

  static const minutes60 = AchievementDefinition(
    id: 'minutes_60',
    title: 'One Hour',
    description: 'Accumulate 60 minutes of practice.',
    type: AchievementRequirementType.totalMinutes,
    threshold: 60,
  );

  static const minutes600 = AchievementDefinition(
    id: 'minutes_600',
    title: 'Ten Hours',
    description: 'Accumulate 10 hours of practice.',
    type: AchievementRequirementType.totalMinutes,
    threshold: 600,
  );

  static const days7 = AchievementDefinition(
    id: 'days_7',
    title: 'First Week',
    description: 'Practice on 7 different days.',
    type: AchievementRequirementType.distinctDaysPracticed,
    threshold: 7,
  );

  static const days30 = AchievementDefinition(
    id: 'days_30',
    title: 'Thirty Days Practiced',
    description: 'Practice on 30 different days.',
    type: AchievementRequirementType.distinctDaysPracticed,
    threshold: 30,
  );

  static const streak3 = AchievementDefinition(
    id: 'streak_3',
    title: 'Three In A Row',
    description: 'Reach a 3 day streak.',
    type: AchievementRequirementType.streakDays,
    threshold: 3,
  );

  static const streak7 = AchievementDefinition(
    id: 'streak_7',
    title: 'One Week Streak',
    description: 'Reach a 7 day streak.',
    type: AchievementRequirementType.streakDays,
    threshold: 7,
  );

  static const streak30 = AchievementDefinition(
    id: 'streak_30',
    title: 'One Month Streak',
    description: 'Reach a 30 day streak.',
    type: AchievementRequirementType.streakDays,
    threshold: 30,
  );

  // Threshold intentionally hardcoded rather than importing
  // BreathingMode.values.length from the breathing feature's domain layer —
  // keep in sync manually if the technique catalog grows.
  static const techniqueVariety = AchievementDefinition(
    id: 'technique_variety',
    title: 'Explorer',
    description: 'Try 5 different breathing techniques.',
    type: AchievementRequirementType.techniqueVariety,
    threshold: 5,
  );

  static const List<AchievementDefinition> values = [
    firstSession,
    sessions10,
    sessions50,
    sessions100,
    minutes60,
    minutes600,
    days7,
    days30,
    streak3,
    streak7,
    streak30,
    techniqueVariety,
  ];
}
