import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/breathing_settings.dart';
import '../repositories/breathing_repository.dart';

class GetBreathingSettings {
  final BreathingRepository repository;

  GetBreathingSettings(this.repository);

  Future<Either<Failure, BreathingSettings>> call() async {
    return await repository.getSettings();
  }
}
