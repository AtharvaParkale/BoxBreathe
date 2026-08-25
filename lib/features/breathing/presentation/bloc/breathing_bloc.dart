import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../history/domain/usecases/log_completed_session.dart';
import '../../../history/domain/usecases/log_remote_session.dart';
import '../../domain/entities/breathing_settings.dart';
import '../../domain/usecases/get_breathing_settings.dart';
import '../../domain/usecases/save_breathing_settings.dart';
import 'breathing_event.dart';
import 'breathing_state.dart';

class BreathingBloc extends Bloc<BreathingEvent, BreathingState> {
  final GetBreathingSettings getSettings;
  final SaveBreathingSettings saveSettings;
  final LogCompletedSession logCompletedSession;
  final LogRemoteSession logRemoteSession;

  StreamSubscription<int>? _tickerSubscription;
  DateTime? _sessionStartedAt;

  BreathingBloc({
    required this.getSettings,
    required this.saveSettings,
    required this.logCompletedSession,
    required this.logRemoteSession,
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
    result.fold((failure) => null, (settings) {
      emit(
        state.copyWith(
          mode: settings.mode,
          sessionDurationMinutes: settings.durationMinutes,
          sessionRemainingSeconds: _secondsFor(settings.durationMinutes),
        ),
      );
    });
  }

  void _onStart(StartBreathing event, Emitter<BreathingState> emit) {
    if (state.status == BreathingStatus.active) return;
    _sessionStartedAt = DateTime.now();
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
    emit(
      state.copyWith(
        status: BreathingStatus.initial,
        sessionRemainingSeconds: _secondsFor(state.sessionDurationMinutes),
      ),
    );
  }

  void _onChangeMode(ChangeBreathingMode event, Emitter<BreathingState> emit) {
    _tickerSubscription?.cancel();
    saveSettings(
      BreathingSettings(
        mode: event.mode,
        durationMinutes: state.sessionDurationMinutes,
      ),
    );

    emit(
      state.copyWith(
        mode: event.mode,
        status: BreathingStatus.initial,
        sessionRemainingSeconds: _secondsFor(state.sessionDurationMinutes),
      ),
    );
  }

  void _onChangeDuration(
    ChangeSessionDuration event,
    Emitter<BreathingState> emit,
  ) {
    emit(
      state.copyWith(
        sessionDurationMinutes: event.durationMinutes,
        sessionRemainingSeconds: _secondsFor(event.durationMinutes),
      ),
    );
    add(StopBreathing());
    saveSettings(
      BreathingSettings(mode: state.mode, durationMinutes: event.durationMinutes),
    );
  }

  void _startTicker() {
    _tickerSubscription?.cancel();
    _tickerSubscription = Stream.periodic(const Duration(seconds: 1), (x) => x)
        .listen((_) {
          add(TimerTick());
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
        emit(
          state.copyWith(
            status: BreathingStatus.completed,
            sessionRemainingSeconds: 0,
          ),
        );
        // Only sessions that finish naturally count — logged as a
        // fire-and-forget side effect, decoupled from the emitted state.
        final completedDurationSeconds = state.sessionDurationMinutes * 60;
        unawaited(logCompletedSession(completedDurationSeconds));
        final startedAt = _sessionStartedAt ?? DateTime.now();
        unawaited(
          logRemoteSession(
            techniqueId: state.mode.id,
            techniqueName: state.mode.name,
            durationSeconds: completedDurationSeconds,
            completedDurationSeconds: completedDurationSeconds,
            startedAt: startedAt,
            completedAt: DateTime.now(),
            completed: true,
          ),
        );
        return;
      }
    }

    emit(state.copyWith(sessionRemainingSeconds: newSessionRemaining));
  }

  int _secondsFor(int minutes) => minutes == -1 ? -1 : minutes * 60;
}
