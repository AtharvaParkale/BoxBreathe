import 'package:hive/hive.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/session_history.dart';

abstract class HistoryLocalDataSource {
  Future<SessionHistory> getHistory();
  Future<void> logCompletedSession(int durationSeconds);
}

class HistoryLocalDataSourceImpl implements HistoryLocalDataSource {
  final Box box;
  static const String keyTotalSessions = 'history_total_sessions';
  static const String keyTotalSeconds = 'history_total_seconds';

  HistoryLocalDataSourceImpl(this.box);

  @override
  Future<SessionHistory> getHistory() async {
    try {
      final totalSessions = box.get(keyTotalSessions, defaultValue: 0) as int;
      final totalSeconds = box.get(keyTotalSeconds, defaultValue: 0) as int;
      return SessionHistory(
        totalSessions: totalSessions,
        totalSeconds: totalSeconds,
      );
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> logCompletedSession(int durationSeconds) async {
    try {
      final currentSessions = box.get(keyTotalSessions, defaultValue: 0) as int;
      final currentSeconds = box.get(keyTotalSeconds, defaultValue: 0) as int;
      await box.put(keyTotalSessions, currentSessions + 1);
      await box.put(keyTotalSeconds, currentSeconds + durationSeconds);
    } catch (e) {
      throw CacheException();
    }
  }
}
