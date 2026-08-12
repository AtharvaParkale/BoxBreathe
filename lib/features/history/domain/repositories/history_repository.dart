import 'package:dartz/dartz.dart';
import '../entities/session_history.dart';
import '../../../../core/error/failures.dart';

abstract class HistoryRepository {
  Future<Either<Failure, SessionHistory>> getHistory();
  Future<Either<Failure, void>> logCompletedSession(int durationSeconds);
}
