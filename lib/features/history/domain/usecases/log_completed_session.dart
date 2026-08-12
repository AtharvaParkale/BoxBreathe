import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/history_repository.dart';

class LogCompletedSession {
  final HistoryRepository repository;

  LogCompletedSession(this.repository);

  Future<Either<Failure, void>> call(int durationSeconds) async {
    return await repository.logCompletedSession(durationSeconds);
  }
}
