import 'package:equatable/equatable.dart';
import '../../../../core/theme/app_theme.dart';

class Settings extends Equatable {
  final AppThemeMode themeMode;
  final bool isSoundEnabled;
  final bool isHapticEnabled;
  final int dailyReminderHour; // -1 if disabled
  final int dailyReminderMinute;

  const Settings({
    required this.themeMode,
    required this.isSoundEnabled,
    required this.isHapticEnabled,
    this.dailyReminderHour = -1,
    this.dailyReminderMinute = 0,
  });

  static const defaultSettings = Settings(
    themeMode: AppThemeMode.midnight,
    isSoundEnabled: true,
    isHapticEnabled: true,
  );

  Settings copyWith({
    AppThemeMode? themeMode,
    bool? isSoundEnabled,
    bool? isHapticEnabled,
    int? dailyReminderHour,
    int? dailyReminderMinute,
  }) {
    return Settings(
      themeMode: themeMode ?? this.themeMode,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      isHapticEnabled: isHapticEnabled ?? this.isHapticEnabled,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        isSoundEnabled,
        isHapticEnabled,
        dailyReminderHour,
        dailyReminderMinute
      ];
}
