import 'package:dartz/dartz.dart';
import '../entities/breathing_session_record.dart';
import '../entities/session_history.dart';
import '../../../../core/error/failures.dart';

abstract class HistoryRepository {
  Future<Either<Failure, SessionHistory>> getHistory();
  Future<Either<Failure, void>> logCompletedSession(int durationSeconds);

  /// Mirrors a naturally-completed session to Firestore. Never lets a
  /// remote failure surface as a rejected Future — always resolves to an
  /// `Either`, so callers can safely fire-and-forget it.
  Future<Either<Failure, void>> logRemoteSession(BreathingSessionRecord record);
}
