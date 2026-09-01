import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/breathing_session_record.dart';
import '../repositories/history_repository.dart';

class GetSessionsSince {
  final HistoryRepository repository;

  GetSessionsSince(this.repository);

  Future<Either<Failure, List<BreathingSessionRecord>>> call({
    DateTime? since,
  }) {
    return repository.getSessionsSince(since);
  }
}
