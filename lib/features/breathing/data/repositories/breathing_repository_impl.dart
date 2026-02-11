import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/breathing_settings.dart';
import '../../domain/repositories/breathing_repository.dart';
import '../../data/datasources/breathing_local_data_source.dart';

class BreathingRepositoryImpl implements BreathingRepository {
  final BreathingLocalDataSource localDataSource;

  BreathingRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, BreathingSettings>> getSettings() async {
    try {
      final settings = await localDataSource.getSettings();
      return Right(settings);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> saveSettings(BreathingSettings settings) async {
    try {
      await localDataSource.saveSettings(settings);
      return const Right(null);
    } on CacheException {
      return Left(CacheFailure());
    }
  }
}
