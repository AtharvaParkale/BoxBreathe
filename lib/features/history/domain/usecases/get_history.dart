import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/session_history.dart';
import '../repositories/history_repository.dart';

class GetHistory {
  final HistoryRepository repository;

  GetHistory(this.repository);

  Future<Either<Failure, SessionHistory>> call() async {
    return await repository.getHistory();
  }
}
