import 'package:hive/hive.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/settings.dart';

abstract class SettingsLocalDataSource {
  Future<Settings> getSettings();
  Future<void> saveSettings(Settings settings);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final Box box;
  static const String keyTheme = 'settings_theme';
  static const String keySound = 'settings_sound';
  static const String keyHaptic = 'settings_haptic';
  static const String keyReminderHour = 'settings_reminder_hour';
  static const String keyReminderMinute = 'settings_reminder_minute';

  SettingsLocalDataSourceImpl(this.box);

  @override
  Future<Settings> getSettings() async {
    try {
      final themeIndex = box.get(keyTheme, defaultValue: 0) as int;
      final sound = box.get(keySound, defaultValue: true) as bool;
      final haptic = box.get(keyHaptic, defaultValue: true) as bool;
      final reminderHour = box.get(keyReminderHour, defaultValue: -1) as int;
      final reminderMinute = box.get(keyReminderMinute, defaultValue: 0) as int;

      final themeMode = AppThemeMode.values.elementAtOrNull(themeIndex) ??
          AppThemeMode.midnight;

      return Settings(
        themeMode: themeMode,
        isSoundEnabled: sound,
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
      await box.put(keyTheme, settings.themeMode.index);
      await box.put(keySound, settings.isSoundEnabled);
      await box.put(keyHaptic, settings.isHapticEnabled);
      await box.put(keyReminderHour, settings.dailyReminderHour);
      await box.put(keyReminderMinute, settings.dailyReminderMinute);
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
