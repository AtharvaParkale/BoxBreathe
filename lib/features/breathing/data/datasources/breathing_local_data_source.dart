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

  // Legacy key: the selected mode used to be persisted as a positional
  // index into BreathingMode.values. That list has since been curated
  // from 13 techniques down to 5, so an old index no longer points at
  // the same technique. Kept only to support the one-time migration
  // below; never written to anymore.
  static const String legacyKeyModeIndex = 'breathing_mode_index';

  // The 13-technique order BreathingMode.values used to have, by name,
  // frozen here so the migration below still works after values shrank.
  // A null entry means that technique was removed in the curation and
  // has no direct successor.
  static const List<String?> _legacyModeIdsByIndex = [
    'box', // Box
    'calm478', // Calm (now "4-7-8")
    'quickReset', // Quick Reset
    'sleep', // Sleep
    null, // Wim Hof — removed
    null, // Deep Breathing — removed
    null, // Relaxed Hold — removed
    null, // Quick Breathing — removed
    null, // Equal Breathing — removed
    'coherence', // Coherence
    null, // Pursed Lip — removed
    null, // 7-11 Relax — removed
    null, // Triangular — removed
  ];

  static const String keyModeId = 'breathing_mode_id';
  static const String keyDuration = 'breathing_duration';

  BreathingLocalDataSourceImpl(this.box);

  @override
  Future<BreathingSettings> getSettings() async {
    try {
      final duration = box.get(keyDuration, defaultValue: 3) as int;
      final modeId = await _resolveModeId();
      final mode =
          BreathingMode.values.firstWhere(
            (m) => m.id == modeId,
            orElse: () => BreathingMode.box,
          );

      return BreathingSettings(mode: mode, durationMinutes: duration);
    } catch (e) {
      throw CacheException();
    }
  }

  /// Reads the current mode id, migrating the legacy positional-index
  /// key to the new stable-id key the first time this runs.
  Future<String> _resolveModeId() async {
    final storedId = box.get(keyModeId) as String?;
    if (storedId != null) return storedId;

    final legacyIndex = box.get(legacyKeyModeIndex) as int?;
    final migratedId =
        (legacyIndex != null &&
            legacyIndex >= 0 &&
            legacyIndex < _legacyModeIdsByIndex.length)
        ? _legacyModeIdsByIndex[legacyIndex] ?? BreathingMode.box.id
        : BreathingMode.box.id;

    await box.put(keyModeId, migratedId);
    if (legacyIndex != null) await box.delete(legacyKeyModeIndex);
    return migratedId;
  }

  @override
  Future<void> saveSettings(BreathingSettings settings) async {
    try {
      await box.put(keyModeId, settings.mode.id);
      await box.put(keyDuration, settings.durationMinutes);
    } catch (e) {
      throw CacheException();
    }
  }
}
