import 'package:hive/hive.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/settings.dart';

abstract class SettingsLocalDataSource {
  Future<Settings> getSettings();
  Future<void> saveSettings(Settings settings);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final Box box;
  static const String keySound = 'settings_sound';
  static const String keySoundCue = 'settings_sound_cue';
  static const String keyHaptic = 'settings_haptic';
  static const String keyReminderHour = 'settings_reminder_hour';
  static const String keyReminderMinute = 'settings_reminder_minute';

  SettingsLocalDataSourceImpl(this.box);

  @override
  Future<Settings> getSettings() async {
    try {
      final sound = box.get(keySound, defaultValue: true) as bool;
      final soundCue = box.get(keySoundCue, defaultValue: 'bell') as String;
      final haptic = box.get(keyHaptic, defaultValue: true) as bool;
      final reminderHour = box.get(keyReminderHour, defaultValue: -1) as int;
      final reminderMinute = box.get(keyReminderMinute, defaultValue: 0) as int;

      return Settings(
        isSoundEnabled: sound,
        soundCue: soundCue,
        isHapticEnabled: haptic,
        dailyReminderHour: reminderHour,
        dailyReminderMinute: reminderMinute,
      );
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> saveSettings(Settings settings) async {
    try {
      await box.put(keySound, settings.isSoundEnabled);
      await box.put(keySoundCue, settings.soundCue);
      await box.put(keyHaptic, settings.isHapticEnabled);
      await box.put(keyReminderHour, settings.dailyReminderHour);
      await box.put(keyReminderMinute, settings.dailyReminderMinute);
    } catch (e) {
      throw CacheException();
    }
  }
}
