import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/post_session_reward.dart';
import '../repositories/progress_repository.dart';

class GetPostSessionReward {
  final ProgressRepository repository;

  GetPostSessionReward(this.repository);

  Future<Either<Failure, PostSessionReward>> call() {
    return repository.evaluatePostSessionReward();
  }
}
