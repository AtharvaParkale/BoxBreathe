import 'package:hive/hive.dart';
import '../../../../core/error/exceptions.dart'; // Need to create exceptions
import '../../domain/entities/breathing_mode.dart';
import '../../domain/entities/breathing_settings.dart';

abstract class BreathingLocalDataSource {
  Future<BreathingSettings> getSettings();
  Future<void> saveSettings(BreathingSettings settings);
}

class BreathingLocalDataSourceImpl implements BreathingLocalDataSource {
  final Box box;
  static const String keyModeIndex = 'breathing_mode_index';
  static const String keyDuration = 'breathing_duration';

  BreathingLocalDataSourceImpl(this.box);

  @override
  Future<BreathingSettings> getSettings() async {
    try {
      final modeIndex = box.get(keyModeIndex, defaultValue: 0) as int;
      final duration = box.get(keyDuration, defaultValue: 3) as int;
      
      final mode = BreathingMode.values.elementAtOrNull(modeIndex) ?? BreathingMode.box;

      return BreathingSettings(
        mode: mode,
        durationMinutes: duration,
      );
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> saveSettings(BreathingSettings settings) async {
    try {
      final modeIndex = BreathingMode.values.indexOf(settings.mode);
      await box.put(keyModeIndex, modeIndex);
      await box.put(keyDuration, settings.durationMinutes);
    } catch (e) {
      throw CacheException();
    }
  }
}

extension ListGetOrNull on List {
    dynamic elementAtOrNull(int index) {
        if (index < 0 || index >= length) return null;
        return this[index];
    }
}
