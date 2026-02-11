import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/breathing_settings.dart';
import '../../domain/usecases/get_breathing_settings.dart';
import '../../domain/usecases/save_breathing_settings.dart';
import 'breathing_event.dart';
import 'breathing_state.dart';

class BreathingBloc extends Bloc<BreathingEvent, BreathingState> {
  final GetBreathingSettings getSettings;
  final SaveBreathingSettings saveSettings;

  StreamSubscription<int>? _tickerSubscription;

  BreathingBloc({
    required this.getSettings,
    required this.saveSettings,
  }) : super(BreathingState.initial()) {
    on<LoadBreathingSettings>(_onLoadSettings);
    on<StartBreathing>(_onStart);
    on<PauseBreathing>(_onPause);
    on<ResumeBreathing>(_onResume);
    on<StopBreathing>(_onStop);
    on<ChangeBreathingMode>(_onChangeMode);
    on<ChangeSessionDuration>(_onChangeDuration);
    on<TimerTick>(_onTick);
  }

  Future<void> _onLoadSettings(
    LoadBreathingSettings event,
    Emitter<BreathingState> emit,
  ) async {
    final result = await getSettings();
    result.fold(
      (failure) => null,
      (settings) {
        emit(state.copyWith(
          mode: settings.mode,
          // ALWAYS default to 3 minutes on load, ignoring saved duration
          sessionDurationMinutes: 3,
          sessionRemainingSeconds: 3 * 60,
        ));
      },
    );
  }

  void _onStart(StartBreathing event, Emitter<BreathingState> emit) {
    if (state.status == BreathingStatus.active) return;
    emit(state.copyWith(status: BreathingStatus.active));
    _startTicker();
  }

  void _onPause(PauseBreathing event, Emitter<BreathingState> emit) {
    _tickerSubscription?.pause();
    emit(state.copyWith(status: BreathingStatus.paused));
  }

  void _onResume(ResumeBreathing event, Emitter<BreathingState> emit) {
    _tickerSubscription?.resume();
    emit(state.copyWith(status: BreathingStatus.active));
  }

  void _onStop(StopBreathing event, Emitter<BreathingState> emit) {
    _tickerSubscription?.cancel();
    emit(state.copyWith(
      status: BreathingStatus.initial,
      sessionRemainingSeconds: state.sessionDurationMinutes == -1
          ? -1
          : state.sessionDurationMinutes * 60,
    ));
  }

  void _onChangeMode(ChangeBreathingMode event, Emitter<BreathingState> emit) {
    _tickerSubscription?.cancel();
    // Only save the mode, not the duration (since duration is temp)
    saveSettings(BreathingSettings(
      mode: event.mode,
      durationMinutes: 3, // Default to 3 in storage just in case
    ));

    emit(state.copyWith(
      mode: event.mode,
      status: BreathingStatus.initial,
      sessionDurationMinutes: 3,
      sessionRemainingSeconds: 3 * 60,
    ));
  }

  void _onChangeDuration(
      ChangeSessionDuration event, Emitter<BreathingState> emit) {
    // Do NOT save settings. Duration is temporary.
    
    emit(state.copyWith(
      sessionDurationMinutes: event.durationMinutes,
      sessionRemainingSeconds: event.durationMinutes == -1
          ? -1
          : event.durationMinutes * 60,
    ));
    add(StopBreathing());
  }

  void _startTicker() {
    _tickerSubscription?.cancel();
    _tickerSubscription =
        Stream.periodic(const Duration(seconds: 1), (x) => x).listen((_) {
      add(TimerTick(
        sessionRemaining: state.sessionRemainingSeconds,
      ));
    });
  }

  void _onTick(TimerTick event, Emitter<BreathingState> emit) {
    if (state.status != BreathingStatus.active) return;

    // Update Session Timer
    int newSessionRemaining = state.sessionRemainingSeconds;
    if (state.sessionDurationMinutes != -1) {
       newSessionRemaining = state.sessionRemainingSeconds - 1;
       if (newSessionRemaining <= 0) {
         _tickerSubscription?.cancel();
         
         // 1. Emit Completed (triggers UI "DONE", haptics, stop animation)
         emit(state.copyWith(
           status: BreathingStatus.completed,
           sessionRemainingSeconds: 0,
         ));

         // 2. Reset to Default 3 Minutes (triggers UI "READY", reset animation)
         emit(state.copyWith(
            status: BreathingStatus.initial,
            sessionDurationMinutes: 3,
            sessionRemainingSeconds: 3 * 60,
         ));
         return;
       }
    }

    emit(state.copyWith(
      sessionRemainingSeconds: newSessionRemaining,
    ));
  }
}
