import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/id_generator.dart';
import '../../../../core/utils/date_key.dart';
import '../../../history/domain/usecases/log_completed_session.dart';
import '../../../history/domain/usecases/log_remote_session.dart';
import '../../../progress/domain/usecases/get_post_session_reward.dart';
import '../../../progress/domain/usecases/log_progress_session.dart';
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
  final LogProgressSession logProgressSession;
  final GetPostSessionReward getPostSessionReward;
  final IdGenerator idGenerator;

  StreamSubscription<int>? _tickerSubscription;
  DateTime? _sessionStartedAt;

  BreathingBloc({
    required this.getSettings,
    required this.saveSettings,
    required this.logCompletedSession,
    required this.logRemoteSession,
    required this.logProgressSession,
    required this.getPostSessionReward,
    required this.idGenerator,
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
    emit(
      state.copyWith(
        status: BreathingStatus.active,
        clearPostSessionReward: true,
      ),
    );
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
        clearPostSessionReward: true,
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

  Future<void> _onTick(TimerTick event, Emitter<BreathingState> emit) async {
    if (state.status != BreathingStatus.active) return;

    // Update Session Timer
    int newSessionRemaining = state.sessionRemainingSeconds;
    if (state.sessionDurationMinutes != -1) {
      newSessionRemaining = state.sessionRemainingSeconds - 1;
      if (newSessionRemaining <= 0) {
        _tickerSubscription?.cancel();

        // Only sessions that finish naturally count.
        final completedDurationSeconds = state.sessionDurationMinutes * 60;
        final startedAt = _sessionStartedAt ?? DateTime.now();
        final completedAt = DateTime.now();
        final sessionId = idGenerator.newId();
        final dateKeyLocal = dateKeyFor(completedAt.toLocal());

        unawaited(logCompletedSession(completedDurationSeconds));

        // Local progress write is a fast Hive `put` — awaited so the
        // post-session reward below can be computed synchronously and
        // included directly in the emitted state, rather than the page
        // racing a separate fetch against this fire-and-forget write.
        await logProgressSession(
          sessionId: sessionId,
          techniqueId: state.mode.id,
          techniqueName: state.mode.name,
          completedDurationSeconds: completedDurationSeconds,
          startedAt: startedAt,
          completedAt: completedAt,
          dateKeyLocal: dateKeyLocal,
        );
        final reward = await getPostSessionReward();

        emit(
          state.copyWith(
            status: BreathingStatus.completed,
            sessionRemainingSeconds: 0,
            postSessionStreakDays: reward.fold(
              (_) => null,
              (r) => r.streakDays,
            ),
            postSessionAchievementTitle: reward.fold(
              (_) => null,
              (r) => r.newlyUnlockedTitle,
            ),
          ),
        );

        // Firestore mirror stays fire-and-forget, now sharing the same
        // client-minted id and dateKey as the local record.
        unawaited(
          logRemoteSession(
            sessionId: sessionId,
            techniqueId: state.mode.id,
            techniqueName: state.mode.name,
            durationSeconds: completedDurationSeconds,
            completedDurationSeconds: completedDurationSeconds,
            startedAt: startedAt,
            completedAt: completedAt,
            completed: true,
            dateKeyLocal: dateKeyLocal,
          ),
        );
        return;
      }
    }

    emit(state.copyWith(sessionRemainingSeconds: newSessionRemaining));
  }

  int _secondsFor(int minutes) => minutes == -1 ? -1 : minutes * 60;
}
