import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/breathing_session_record.dart';
import '../repositories/history_repository.dart';

class LogRemoteSession {
  final HistoryRepository repository;

  LogRemoteSession(this.repository);

  Future<Either<Failure, void>> call({
    required String sessionId,
    required String techniqueId,
    required String techniqueName,
    required int durationSeconds,
    required int completedDurationSeconds,
    required DateTime startedAt,
    required DateTime completedAt,
    required bool completed,
    required String dateKeyLocal,
    String? reason,
  }) async {
    return await repository.logRemoteSession(
      BreathingSessionRecord(
        id: sessionId,
        techniqueId: techniqueId,
        techniqueName: techniqueName,
        durationSeconds: durationSeconds,
        completedDurationSeconds: completedDurationSeconds,
        startedAt: startedAt,
        completedAt: completedAt,
        completed: completed,
        dateKeyLocal: dateKeyLocal,
        reason: reason,
      ),
    );
  }
}
