import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/breathing_session_record.dart';
import '../../domain/entities/session_history.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_local_data_source.dart';
import '../datasources/history_remote_data_source.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryLocalDataSource localDataSource;
  final HistoryRemoteDataSource remoteDataSource;
  final AuthRepository authRepository;

  HistoryRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.authRepository,
  });

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

  @override
  Future<Either<Failure, void>> logRemoteSession(
    BreathingSessionRecord record,
  ) async {
    // Unconditional catch-all: this must never let a Firestore failure (or
    // anything else) propagate as a rejected Future into the bloc's
    // fire-and-forget call site. Firestore's own offline queue means a
    // dropped network connection isn't even an error case here — only
    // genuine failures (bad data, permission-denied) hit the catch.
    try {
      final uid = authRepository.currentUser?.uid;
      if (uid == null) {
        // Anonymous sign-in hasn't resolved yet (cold-start race). Local
        // Hive counters are still correct; there's just no remote record
        // for this particular session.
        return const Right(null);
      }
      await remoteDataSource.logSession(uid: uid, record: record);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
