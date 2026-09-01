import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/progress_session_record.dart';
import '../repositories/progress_repository.dart';

class GetRecentSessions {
  final ProgressRepository repository;

  GetRecentSessions(this.repository);

  Future<Either<Failure, List<ProgressSessionRecord>>> call({
    int limit = 10,
  }) {
    return repository.getRecentSessions(limit: limit);
  }
}
