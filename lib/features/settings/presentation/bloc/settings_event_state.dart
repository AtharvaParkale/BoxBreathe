import 'package:equatable/equatable.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/settings.dart';

// Events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object> get props => [];
}

class LoadSettings extends SettingsEvent {}

class ChangeTheme extends SettingsEvent {
  final AppThemeMode themeMode;
  const ChangeTheme(this.themeMode);
  @override
  List<Object> get props => [themeMode];
}

class ToggleSound extends SettingsEvent {
  final bool isEnabled;
  const ToggleSound(this.isEnabled);
  @override
  List<Object> get props => [isEnabled];
}

class ToggleHaptic extends SettingsEvent {
  final bool isEnabled;
  const ToggleHaptic(this.isEnabled);
  @override
  List<Object> get props => [isEnabled];
}

class SetDailyReminder extends SettingsEvent {
  final int hour;
  final int minute;
  const SetDailyReminder(this.hour, this.minute);
  @override
  List<Object> get props => [hour, minute];
}

class CancelDailyReminder extends SettingsEvent {}

// State
class SettingsState extends Equatable {
  final Settings settings;

  const SettingsState({
    this.settings = Settings.defaultSettings,
  });

  SettingsState copyWith({Settings? settings}) {
    return SettingsState(settings: settings ?? this.settings);
  }

  @override
  List<Object> get props => [settings];
}
