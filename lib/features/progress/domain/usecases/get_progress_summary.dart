import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/progress_summary.dart';
import '../repositories/progress_repository.dart';

class GetProgressSummary {
  final ProgressRepository repository;

  GetProgressSummary(this.repository);

  Future<Either<Failure, ProgressSummary>> call({DateTime? forMonth}) {
    return repository.getSummary(forMonth: forMonth);
  }
}
