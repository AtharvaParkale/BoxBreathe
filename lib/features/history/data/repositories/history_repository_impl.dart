import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/session_history.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_local_data_source.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryLocalDataSource localDataSource;

  HistoryRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, SessionHistory>> getHistory() async {
    try {
      final history = await localDataSource.getHistory();
      return Right(history);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logCompletedSession(int durationSeconds) async {
    try {
      await localDataSource.logCompletedSession(durationSeconds);
      return const Right(null);
    } on CacheException {
      return Left(CacheFailure());
    }
  }
}
