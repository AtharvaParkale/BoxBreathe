import 'package:hive/hive.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/progress_session_record.dart';

abstract class ProgressLocalDataSource {
  Future<void> putSession(ProgressSessionRecord record);
  bool hasSession(String id);
  List<ProgressSessionRecord> getAllSessions();

  Future<void> markAchievementUnlocked(String achievementId, DateTime unlockedAt);
  DateTime? getAchievementUnlockedAt(String achievementId);

  int? getLastSyncedMillis(String uid);
  Future<void> setLastSyncedMillis(String uid, int millis);
}

/// Three dedicated Hive boxes, plain `Map<String, dynamic>` values with no
/// typed adapters — matches this codebase's existing zero-adapter
/// convention. `sessionsBox` is one-key-per-record (not a single mega-list
/// key): O(1) writes, a crash only risks the one record being written, and
/// dedup-by-id for sync merges is a trivial `containsKey`.
class ProgressLocalDataSourceImpl implements ProgressLocalDataSource {
  final Box sessionsBox;
  final Box achievementsBox;
  final Box metaBox;

  ProgressLocalDataSourceImpl({
    required this.sessionsBox,
    required this.achievementsBox,
    required this.metaBox,
  });

  static const String _lastSyncedKey = 'last_synced_by_uid';

  @override
  Future<void> putSession(ProgressSessionRecord record) async {
    try {
      await sessionsBox.put(record.id, {
        'id': record.id,
        'techniqueId': record.techniqueId,
        'techniqueName': record.techniqueName,
        'completedDurationSeconds': record.completedDurationSeconds,
        'startedAtMillis': record.startedAt.millisecondsSinceEpoch,
        'completedAtMillis': record.completedAt.millisecondsSinceEpoch,
        'dateKeyLocal': record.dateKeyLocal,
      });
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  bool hasSession(String id) => sessionsBox.containsKey(id);

  @override
  List<ProgressSessionRecord> getAllSessions() {
    try {
      return sessionsBox.values.map((raw) {
        final data = Map<String, dynamic>.from(raw as Map);
        return ProgressSessionRecord(
          id: data['id'] as String,
          techniqueId: data['techniqueId'] as String,
          techniqueName: data['techniqueName'] as String,
          completedDurationSeconds: data['completedDurationSeconds'] as int,
          startedAt: DateTime.fromMillisecondsSinceEpoch(
            data['startedAtMillis'] as int,
          ),
          completedAt: DateTime.fromMillisecondsSinceEpoch(
            data['completedAtMillis'] as int,
          ),
          dateKeyLocal: data['dateKeyLocal'] as String,
        );
      }).toList();
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> markAchievementUnlocked(
    String achievementId,
    DateTime unlockedAt,
  ) async {
    try {
      await achievementsBox.put(achievementId, {
        'unlockedAtMillis': unlockedAt.millisecondsSinceEpoch,
      });
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  DateTime? getAchievementUnlockedAt(String achievementId) {
    final raw = achievementsBox.get(achievementId);
    if (raw == null) return null;
    final data = Map<String, dynamic>.from(raw as Map);
    return DateTime.fromMillisecondsSinceEpoch(data['unlockedAtMillis'] as int);
  }

  @override
  int? getLastSyncedMillis(String uid) {
    final map = metaBox.get(_lastSyncedKey);
    if (map == null) return null;
    return Map<String, dynamic>.from(map as Map)[uid] as int?;
  }

  @override
  Future<void> setLastSyncedMillis(String uid, int millis) async {
    try {
      final existing = metaBox.get(_lastSyncedKey);
      final map = existing == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(existing as Map);
      map[uid] = millis;
      await metaBox.put(_lastSyncedKey, map);
    } catch (e) {
      throw CacheException();
    }
  }
}
