import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notification_helper.dart';

import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/save_settings.dart';
import 'settings_event_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettings getSettings;
  final SaveSettings saveSettings;

  SettingsBloc({required this.getSettings, required this.saveSettings})
    : super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<ToggleSound>(_onToggleSound);
    on<ChangeSoundCue>(_onChangeSoundCue);
    on<ToggleHaptic>(_onToggleHaptic);
    on<SetDailyReminder>(_onSetDailyReminder);
    on<CancelDailyReminder>(_onCancelDailyReminder);
    on<ToggleFavoriteTechnique>(_onToggleFavoriteTechnique);
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

  Future<void> _onToggleSound(
    ToggleSound event,
    Emitter<SettingsState> emit,
  ) async {
    final newSettings = state.settings.copyWith(
      isSoundEnabled: event.isEnabled,
    );
    await saveSettings(newSettings);
    emit(state.copyWith(settings: newSettings));
  }

  Future<void> _onChangeSoundCue(
    ChangeSoundCue event,
    Emitter<SettingsState> emit,
  ) async {
    final newSettings = state.settings.copyWith(soundCue: event.soundCue);
    await saveSettings(newSettings);
    emit(state.copyWith(settings: newSettings));
  }

  Future<void> _onToggleHaptic(
    ToggleHaptic event,
    Emitter<SettingsState> emit,
  ) async {
    final newSettings = state.settings.copyWith(
      isHapticEnabled: event.isEnabled,
    );
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

  Future<void> _onToggleFavoriteTechnique(
    ToggleFavoriteTechnique event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state.settings.favoriteTechniqueIds;
    final updated = current.contains(event.techniqueId)
        ? current.where((id) => id != event.techniqueId).toList()
        : [...current, event.techniqueId];
    final newSettings = state.settings.copyWith(
      favoriteTechniqueIds: updated,
    );
    await saveSettings(newSettings);
    emit(state.copyWith(settings: newSettings));
  }
}
