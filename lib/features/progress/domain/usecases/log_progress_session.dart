import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/progress_session_record.dart';
import '../repositories/progress_repository.dart';

class LogProgressSession {
  final ProgressRepository repository;

  LogProgressSession(this.repository);

  Future<Either<Failure, void>> call({
    required String sessionId,
    required String techniqueId,
    required String techniqueName,
    required int completedDurationSeconds,
    required DateTime startedAt,
    required DateTime completedAt,
    required String dateKeyLocal,
  }) {
    return repository.logSession(
      ProgressSessionRecord(
        id: sessionId,
        techniqueId: techniqueId,
        techniqueName: techniqueName,
        completedDurationSeconds: completedDurationSeconds,
        startedAt: startedAt,
        completedAt: completedAt,
        dateKeyLocal: dateKeyLocal,
      ),
    );
  }
}
