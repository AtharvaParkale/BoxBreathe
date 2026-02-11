import 'package:dartz/dartz.dart';
import '../entities/breathing_settings.dart';
import '../../../../core/error/failures.dart'; // Will need to create this

abstract class BreathingRepository {
  Future<Either<Failure, BreathingSettings>> getSettings();
  Future<Either<Failure, void>> saveSettings(BreathingSettings settings);
}
