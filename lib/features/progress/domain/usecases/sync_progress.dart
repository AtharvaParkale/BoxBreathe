import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/progress_repository.dart';

class SyncProgress {
  final ProgressRepository repository;

  SyncProgress(this.repository);

  Future<Either<Failure, int>> call() {
    return repository.syncFromRemote();
  }
}
