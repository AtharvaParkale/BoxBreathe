import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/date_key.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../breathing/domain/entities/breathing_technique_catalog.dart';
import '../../../history/domain/usecases/get_sessions_since.dart';
import '../../domain/entities/achievement_definition.dart';
import '../../domain/entities/achievement_progress.dart';
import '../../domain/entities/post_session_reward.dart';
import '../../domain/entities/progress_session_record.dart';
import '../../domain/entities/progress_summary.dart';
import '../../domain/entities/streak_info.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/streak_calculator.dart';
import '../datasources/progress_local_data_source.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  final ProgressLocalDataSource localDataSource;
  final GetSessionsSince getSessionsSince;
  final AuthRepository authRepository;

  ProgressRepositoryImpl({
    required this.localDataSource,
    required this.getSessionsSince,
    required this.authRepository,
  });

  @override
  Future<Either<Failure, void>> logSession(ProgressSessionRecord record) async {
    try {
      await localDataSource.putSession(record);
      return const Right(null);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, ProgressSummary>> getSummary({
    DateTime? forMonth,
  }) async {
    try {
      // Only natural completions count toward streaks/achievements/stats.
      // A no-op today (every logged record is completed), but guards
      // against a future change that also logs aborted sessions from
      // silently affecting numbers users already understand.
      final sessions = localDataSource.getAllSessions()
          .where((s) => s.completed)
          .toList();
      final now = DateTime.now();
      final todayKey = dateKeyFor(now);
      final practicedDateKeys = sessions.map((s) => s.dateKeyLocal).toSet();
      final streak = computeStreak(practicedDateKeys, todayKey);

      final totalSeconds = sessions.fold<int>(
        0,
        (sum, s) => sum + s.completedDurationSeconds,
      );
      final lifetime = LifetimeStats(
        totalSessions: sessions.length,
        totalMinutes: totalSeconds ~/ 60,
        totalDaysPracticed: practicedDateKeys.length,
      );

      final thisWeek = _computeWeekSummary(sessions, now);
      final monthlyPracticeCounts = _computeMonthlyCounts(
        sessions,
        forMonth ?? now,
      );
      final byTechnique = _computeTechniqueBreakdown(sessions);
      final personalRecords = _computePersonalRecords(
        sessions,
        streak,
        practicedDateKeys,
      );
      final achievements = await _computeAchievements(sessions, streak);

      return Right(
        ProgressSummary(
          streak: streak,
          lifetime: lifetime,
          thisWeek: thisWeek,
          monthlyPracticeCounts: monthlyPracticeCounts,
          byTechnique: byTechnique,
          personalRecords: personalRecords,
          achievements: achievements.list,
        ),
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> syncFromRemote() async {
    try {
      final uid = authRepository.currentUser?.uid;
      if (uid == null) return const Right(0);

      final lastSyncedMillis = localDataSource.getLastSyncedMillis(uid);
      final since = lastSyncedMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastSyncedMillis);

      final result = await getSessionsSince(since: since);
      return await result.fold((failure) async => Left(failure), (
        records,
      ) async {
        var mergedCount = 0;
        var maxMillis = lastSyncedMillis ?? 0;
        for (final r in records) {
          final millis = r.completedAt.millisecondsSinceEpoch;
          if (millis > maxMillis) maxMillis = millis;
          if (!localDataSource.hasSession(r.id)) {
            await localDataSource.putSession(
              ProgressSessionRecord(
                id: r.id,
                techniqueId: r.techniqueId,
                techniqueName: r.techniqueName,
                completedDurationSeconds: r.completedDurationSeconds,
                startedAt: r.startedAt,
                completedAt: r.completedAt,
                dateKeyLocal: r.dateKeyLocal,
                completed: r.completed,
                reason: r.reason,
              ),
            );
            mergedCount++;
          }
        }
        if (records.isNotEmpty) {
          await localDataSource.setLastSyncedMillis(uid, maxMillis);
        }
        return Right(mergedCount);
      });
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PostSessionReward>> evaluatePostSessionReward() async {
    try {
      final sessions = localDataSource.getAllSessions()
          .where((s) => s.completed)
          .toList();
      final todayKey = dateKeyFor(DateTime.now());
      final practicedDateKeys = sessions.map((s) => s.dateKeyLocal).toSet();
      final streak = computeStreak(practicedDateKeys, todayKey);
      final achievements = await _computeAchievements(sessions, streak);
      return Right(
        PostSessionReward(
          streakDays: streak.current,
          newlyUnlockedTitle: achievements.newlyUnlockedTitle,
        ),
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProgressSessionRecord>>> getRecentSessions({
    int limit = 10,
  }) async {
    try {
      final sessions = localDataSource.getAllSessions()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return Right(sessions.take(limit).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  WeekSummary _computeWeekSummary(
    List<ProgressSessionRecord> sessions,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final mondayOfThisWeek = today.subtract(Duration(days: now.weekday - 1));
    final weekDateKeys = List.generate(
      7,
      (i) => dateKeyFor(mondayOfThisWeek.add(Duration(days: i))),
    );
    final sessionsThisWeek = sessions
        .where((s) => weekDateKeys.contains(s.dateKeyLocal))
        .toList();
    final perDayPracticed = weekDateKeys
        .map((k) => sessionsThisWeek.any((s) => s.dateKeyLocal == k))
        .toList();
    final minutesThisWeek =
        sessionsThisWeek.fold<int>(
          0,
          (sum, s) => sum + s.completedDurationSeconds,
        ) ~/
        60;
    return WeekSummary(
      sessionsThisWeek: sessionsThisWeek.length,
      minutesThisWeek: minutesThisWeek,
      perDayPracticed: perDayPracticed,
    );
  }

  Map<int, int> _computeMonthlyCounts(
    List<ProgressSessionRecord> sessions,
    DateTime now,
  ) {
    final counts = <int, int>{};
    for (final s in sessions) {
      if (s.completedAt.year == now.year && s.completedAt.month == now.month) {
        counts[s.completedAt.day] = (counts[s.completedAt.day] ?? 0) + 1;
      }
    }
    return counts;
  }

  List<TechniqueBreakdownEntry> _computeTechniqueBreakdown(
    List<ProgressSessionRecord> sessions,
  ) {
    final byTechnique = <String, List<ProgressSessionRecord>>{};
    for (final s in sessions) {
      byTechnique.putIfAbsent(s.techniqueId, () => []).add(s);
    }
    final total = sessions.length;
    final entries =
        byTechnique.entries.map((entry) {
          final list = entry.value;
          final minutes =
              list.fold<int>(0, (sum, s) => sum + s.completedDurationSeconds) ~/
              60;
          // Prefer the live catalog name so a technique renamed after a
          // session was logged (e.g. Quick Reset -> Pre-Meeting Reset)
          // displays consistently, falling back to the persisted name for
          // ids no longer in the catalog.
          final catalogName = BreathingTechniqueCatalog.exists(entry.key)
              ? BreathingTechniqueCatalog.byId(entry.key).name
              : null;
          return TechniqueBreakdownEntry(
            techniqueId: entry.key,
            techniqueName: catalogName ?? list.first.techniqueName,
            sessionCount: list.length,
            totalMinutes: minutes,
            percentage: total == 0 ? 0 : list.length / total,
          );
        }).toList()
        ..sort((a, b) => b.sessionCount.compareTo(a.sessionCount));
    return entries;
  }

  PersonalRecords _computePersonalRecords(
    List<ProgressSessionRecord> sessions,
    StreakInfo streak,
    Set<String> practicedDateKeys,
  ) {
    if (sessions.isEmpty) {
      return PersonalRecords.empty;
    }
    final sessionsByDay = <String, int>{};
    for (final s in sessions) {
      sessionsByDay[s.dateKeyLocal] = (sessionsByDay[s.dateKeyLocal] ?? 0) + 1;
    }
    final mostInOneDay = sessionsByDay.values.reduce((a, b) => a > b ? a : b);
    final longestSessionMinutes =
        sessions
            .map((s) => s.completedDurationSeconds)
            .reduce((a, b) => a > b ? a : b) ~/
        60;
    return PersonalRecords(
      longestStreakDays: streak.longest,
      longestSessionMinutes: longestSessionMinutes,
      mostSessionsInOneDay: mostInOneDay,
      totalDaysPracticed: practicedDateKeys.length,
    );
  }

  /// Shared by [getSummary] and [evaluatePostSessionReward] so an
  /// achievement is unlocked (and persisted) exactly once, whichever call
  /// site discovers it first — including sync-merged historical sessions,
  /// not just fresh completions.
  Future<({List<AchievementProgress> list, String? newlyUnlockedTitle})>
  _computeAchievements(
    List<ProgressSessionRecord> sessions,
    StreakInfo streak,
  ) async {
    final totalSessions = sessions.length;
    final totalMinutes =
        sessions.fold<int>(0, (sum, s) => sum + s.completedDurationSeconds) ~/
        60;
    final distinctDays = sessions.map((s) => s.dateKeyLocal).toSet().length;
    final distinctTechniques = sessions.map((s) => s.techniqueId).toSet().length;

    String? newlyUnlockedTitle;
    final list = <AchievementProgress>[];
    for (final def in AchievementDefinition.values) {
      final num current = switch (def.type) {
        AchievementRequirementType.totalSessions => totalSessions,
        AchievementRequirementType.totalMinutes => totalMinutes,
        AchievementRequirementType.distinctDaysPracticed => distinctDays,
        // Peak streak ever attained, never the live current streak — a
        // later broken streak must never un-unlock this achievement.
        AchievementRequirementType.streakDays => streak.longest,
        AchievementRequirementType.techniqueVariety => distinctTechniques,
      };
      final unlocked = current >= def.threshold;
      var unlockedAt = localDataSource.getAchievementUnlockedAt(def.id);
      if (unlocked && unlockedAt == null) {
        unlockedAt = DateTime.now();
        await localDataSource.markAchievementUnlocked(def.id, unlockedAt);
        newlyUnlockedTitle ??= def.title;
      }
      list.add(
        AchievementProgress(
          definition: def,
          current: current,
          unlocked: unlocked,
          unlockedAt: unlockedAt,
        ),
      );
    }
    return (list: list, newlyUnlockedTitle: newlyUnlockedTitle);
  }
}
