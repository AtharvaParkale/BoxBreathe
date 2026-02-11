import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/breathing_mode.dart';
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
      (failure) => null, // Keep default
      (settings) {
        emit(state.copyWith(
          mode: settings.mode,
          sessionDurationMinutes: settings.durationMinutes,
          sessionRemainingSeconds: settings.durationMinutes == -1
              ? -1
              : settings.durationMinutes * 60,
          currentPhase: BreathingPhase.inhale,
          phaseRemainingSeconds: settings.mode.inhaleDuration,
          phaseLabel: 'Inhale',
        ));
      },
    );
     add(StartBreathing());
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
      currentPhase: BreathingPhase.inhale,
      phaseRemainingSeconds: state.mode.inhaleDuration,
      phaseLabel: 'Inhale',
    ));
  }

  void _onChangeMode(ChangeBreathingMode event, Emitter<BreathingState> emit) {
    _tickerSubscription?.cancel();
    saveSettings(BreathingSettings(
      mode: event.mode,
      durationMinutes: state.sessionDurationMinutes,
    ));

    emit(state.copyWith(
      mode: event.mode,
      status: BreathingStatus.initial,
      currentPhase: BreathingPhase.inhale,
      phaseRemainingSeconds: event.mode.inhaleDuration,
      phaseLabel: 'Inhale',
    ));
    add(StartBreathing());
  }

  void _onChangeDuration(
      ChangeSessionDuration event, Emitter<BreathingState> emit) {
    saveSettings(BreathingSettings(
      mode: state.mode,
      durationMinutes: event.durationMinutes,
    ));

    emit(state.copyWith(
      sessionDurationMinutes: event.durationMinutes,
      sessionRemainingSeconds: event.durationMinutes == -1
          ? -1
          : event.durationMinutes * 60,
    ));
    add(StopBreathing());
    add(StartBreathing());
  }

  void _startTicker() {
    _tickerSubscription?.cancel();
    _tickerSubscription =
        Stream.periodic(const Duration(seconds: 1), (x) => x).listen((_) {
      add(TimerTick(
        sessionRemaining: state.sessionRemainingSeconds,
        phaseRemaining: state.phaseRemainingSeconds,
      ));
    });
  }

  void _onTick(TimerTick event, Emitter<BreathingState> emit) {
    if (state.status != BreathingStatus.active) return;

    // 1. Update Session Timer
    int newSessionRemaining = state.sessionRemainingSeconds;
    if (state.sessionDurationMinutes != -1) {
       newSessionRemaining = state.sessionRemainingSeconds - 1;
       if (newSessionRemaining <= 0) {
         _tickerSubscription?.cancel();
         emit(state.copyWith(
           status: BreathingStatus.completed,
           sessionRemainingSeconds: 0,
         ));
         return;
       }
    }

    // 2. Update Phase Timer
    int newPhaseRemaining = state.phaseRemainingSeconds - 1;
    BreathingPhase newPhase = state.currentPhase;
    String newLabel = state.phaseLabel;

    if (newPhaseRemaining <= 0) {
      // Transition to next phase
      switch (state.currentPhase) {
        case BreathingPhase.inhale:
          if (state.mode.holdFullDuration > 0) {
            newPhase = BreathingPhase.holdFull;
            newPhaseRemaining = state.mode.holdFullDuration;
            newLabel = 'Hold';
          } else {
             newPhase = BreathingPhase.exhale;
             newPhaseRemaining = state.mode.exhaleDuration;
             newLabel = 'Exhale';
          }
          break;
        case BreathingPhase.holdFull:
          newPhase = BreathingPhase.exhale;
          newPhaseRemaining = state.mode.exhaleDuration;
          newLabel = 'Exhale';
          break;
        case BreathingPhase.exhale:
          if (state.mode.holdEmptyDuration > 0) {
             newPhase = BreathingPhase.holdEmpty;
             newPhaseRemaining = state.mode.holdEmptyDuration;
             newLabel = 'Hold';
          } else {
             newPhase = BreathingPhase.inhale;
             newPhaseRemaining = state.mode.inhaleDuration;
             newLabel = 'Inhale';
          }
          break;
        case BreathingPhase.holdEmpty:
           newPhase = BreathingPhase.inhale;
           newPhaseRemaining = state.mode.inhaleDuration;
           newLabel = 'Inhale';
           break;
      }
    }

    emit(state.copyWith(
      sessionRemainingSeconds: newSessionRemaining,
      phaseRemainingSeconds: newPhaseRemaining,
      currentPhase: newPhase,
      phaseLabel: newLabel,
    ));
  }
}
