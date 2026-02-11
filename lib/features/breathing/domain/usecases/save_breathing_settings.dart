import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/breathing_settings.dart';
import '../repositories/breathing_repository.dart';

class SaveBreathingSettings {
  final BreathingRepository repository;

  SaveBreathingSettings(this.repository);

  Future<Either<Failure, void>> call(BreathingSettings settings) async {
    return await repository.saveSettings(settings);
  }
}
