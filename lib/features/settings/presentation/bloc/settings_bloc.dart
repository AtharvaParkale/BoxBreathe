import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notification_helper.dart';
import '../../domain/entities/settings.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/save_settings.dart';
import 'settings_event_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettings getSettings;
  final SaveSettings saveSettings;

  SettingsBloc({
    required this.getSettings,
    required this.saveSettings,
  }) : super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<ChangeTheme>(_onChangeTheme);
    on<ToggleSound>(_onToggleSound);
    on<ToggleHaptic>(_onToggleHaptic);
    on<SetDailyReminder>(_onSetDailyReminder);
    on<CancelDailyReminder>(_onCancelDailyReminder);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final result = await getSettings();
    result.fold(
      (failure) => null,
      (settings) => emit(state.copyWith(settings: settings)),
    );
  }

  Future<void> _onChangeTheme(
    ChangeTheme event,
    Emitter<SettingsState> emit,
  ) async {
    final newSettings = state.settings.copyWith(themeMode: event.themeMode);
    await saveSettings(newSettings);
    emit(state.copyWith(settings: newSettings));
  }

  Future<void> _onToggleSound(
    ToggleSound event,
    Emitter<SettingsState> emit,
  ) async {
    final newSettings = state.settings.copyWith(isSoundEnabled: event.isEnabled);
    await saveSettings(newSettings);
    emit(state.copyWith(settings: newSettings));
  }

  Future<void> _onToggleHaptic(
    ToggleHaptic event,
    Emitter<SettingsState> emit,
  ) async {
    final newSettings = state.settings.copyWith(isHapticEnabled: event.isEnabled);
    await saveSettings(newSettings);
    emit(state.copyWith(settings: newSettings));
  }

  Future<void> _onSetDailyReminder(
    SetDailyReminder event,
    Emitter<SettingsState> emit,
  ) async {
    final newSettings = state.settings.copyWith(
      dailyReminderHour: event.hour,
      dailyReminderMinute: event.minute,
    );
    await saveSettings(newSettings);
    emit(state.copyWith(settings: newSettings));
    
    NotificationHelper.scheduleDailyReminder(
      TimeOfDay(hour: event.hour, minute: event.minute),
    );
  }

  Future<void> _onCancelDailyReminder(
    CancelDailyReminder event,
    Emitter<SettingsState> emit,
  ) async {
    final newSettings = state.settings.copyWith(
      dailyReminderHour: -1,
      dailyReminderMinute: 0,
    );
    await saveSettings(newSettings);
    emit(state.copyWith(settings: newSettings));
    
    NotificationHelper.cancelReminders();
  }
}
