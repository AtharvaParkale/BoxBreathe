import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/id_generator.dart';
import '../../../../core/utils/date_key.dart';
import '../../../history/domain/usecases/log_completed_session.dart';
import '../../../history/domain/usecases/log_remote_session.dart';
import '../../../progress/domain/usecases/get_post_session_reward.dart';
import '../../../progress/domain/usecases/has_logged_session.dart';
import '../../../progress/domain/usecases/log_progress_session.dart';
import '../../data/datasources/active_session_storage.dart';
import '../../domain/entities/breathing_settings.dart';
import '../../domain/entities/breathing_technique_catalog.dart';
import '../../domain/session_clock.dart';
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
  final HasLoggedSession hasLoggedSession;
  final IdGenerator idGenerator;
  final ActiveSessionStorage activeSessionStorage;

  /// Injectable so tests can fast-forward without waiting on real seconds;
  /// defaults to the real clock everywhere else.
  final DateTime Function() now;

  StreamSubscription<int>? _tickerSubscription;

  /// The session engine's source of truth while a session is in progress —
  /// mirrored to [activeSessionStorage] on every change so it survives the
  /// bloc instance being torn down (app killed) and can be reconstructed by
  /// `ReconcileSession` on relaunch.
  ActiveSessionSnapshot? _activeSnapshot;

  BreathingBloc({
    required this.getSettings,
    required this.saveSettings,
    required this.logCompletedSession,
    required this.logRemoteSession,
    required this.logProgressSession,
    required this.getPostSessionReward,
    required this.hasLoggedSession,
    required this.idGenerator,
    required this.activeSessionStorage,
    this.now = DateTime.now,
  }) : super(BreathingState.initial()) {
    on<LoadBreathingSettings>(_onLoadSettings);
    on<StartBreathing>(_onStart);
    on<PauseBreathing>(_onPause);
    on<ResumeBreathing>(_onResume);
    on<StopBreathing>(_onStop);
    on<ChangeTechnique>(_onChangeTechnique);
    on<ChangeSessionDuration>(_onChangeDuration);
    on<TimerTick>(_onTick);
    on<ReconcileSession>(_onReconcile);
  }

  Future<void> _onLoadSettings(
    LoadBreathingSettings event,
    Emitter<BreathingState> emit,
  ) async {
    final result = await getSettings();
    result.fold((failure) => null, (settings) {
      emit(
        state.copyWith(
          technique: BreathingTechniqueCatalog.byId(settings.techniqueId),
          sessionDurationMinutes: settings.durationMinutes,
          sessionRemainingSeconds: _secondsFor(settings.durationMinutes),
        ),
      );
    });
  }

  void _onStart(StartBreathing event, Emitter<BreathingState> emit) {
    if (state.status == BreathingStatus.active) return;

    final snapshot = ActiveSessionSnapshot(
      sessionId: idGenerator.newId(),
      techniqueId: state.technique.id,
      sessionDurationMinutes: state.sessionDurationMinutes,
      selectedReason: state.selectedReason,
      startedAt: now(),
      pausedAt: null,
      accumulatedPauseMs: 0,
    );
    _activeSnapshot = snapshot;
    unawaited(activeSessionStorage.save(snapshot));

    emit(
      state.copyWith(
        status: BreathingStatus.active,
        sessionElapsedMs: 0,
        clearPostSessionReward: true,
      ),
    );
    _startTicker();
  }

  void _onPause(PauseBreathing event, Emitter<BreathingState> emit) {
    final snapshot = _activeSnapshot;
    if (snapshot != null && snapshot.pausedAt == null) {
      final paused = snapshot.copyWith(pausedAt: now());
      _activeSnapshot = paused;
      unawaited(activeSessionStorage.save(paused));
    }
    _tickerSubscription?.pause();
    emit(state.copyWith(status: BreathingStatus.paused));
  }

  void _onResume(ResumeBreathing event, Emitter<BreathingState> emit) {
    final snapshot = _activeSnapshot;
    if (snapshot != null && snapshot.pausedAt != null) {
      final pausedMs = now().difference(snapshot.pausedAt!).inMilliseconds;
      final resumed = snapshot.copyWith(
        clearPausedAt: true,
        accumulatedPauseMs: snapshot.accumulatedPauseMs + pausedMs,
      );
      _activeSnapshot = resumed;
      unawaited(activeSessionStorage.save(resumed));
    }
    _tickerSubscription?.resume();
    emit(state.copyWith(status: BreathingStatus.active));
  }

  void _onStop(StopBreathing event, Emitter<BreathingState> emit) {
    _tickerSubscription?.cancel();
    _activeSnapshot = null;
    unawaited(activeSessionStorage.clear());
    emit(
      state.copyWith(
        status: BreathingStatus.initial,
        sessionRemainingSeconds: _secondsFor(state.sessionDurationMinutes),
        sessionElapsedMs: 0,
        clearPostSessionReward: true,
      ),
    );
  }

  void _onChangeTechnique(ChangeTechnique event, Emitter<BreathingState> emit) {
    _tickerSubscription?.cancel();
    _activeSnapshot = null;
    unawaited(activeSessionStorage.clear());
    final technique = BreathingTechniqueCatalog.byId(event.techniqueId);
    saveSettings(
      BreathingSettings(
        techniqueId: technique.id,
        durationMinutes: state.sessionDurationMinutes,
      ),
    );

    emit(
      state.copyWith(
        technique: technique,
        status: BreathingStatus.initial,
        sessionRemainingSeconds: _secondsFor(state.sessionDurationMinutes),
        sessionElapsedMs: 0,
        selectedReason: event.reason,
        clearSelectedReason: event.reason == null,
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
      BreathingSettings(
        techniqueId: state.technique.id,
        durationMinutes: event.durationMinutes,
      ),
    );
  }

  void _startTicker() {
    _tickerSubscription?.cancel();
    _tickerSubscription = Stream.periodic(const Duration(seconds: 1), (x) => x)
        .listen((_) {
          add(TimerTick());
        });
  }

  /// The ticker only wakes the bloc up to recompute — it is never the
  /// clock itself. Elapsed/remaining time and completion are always
  /// derived from [_activeSnapshot] against [now], so this produces the
  /// exact same result whether ticks fired every second (foreground) or
  /// not at all (backgrounded, reconciled later via `ReconcileSession`).
  Future<void> _onTick(TimerTick event, Emitter<BreathingState> emit) async {
    if (state.status != BreathingStatus.active) return;
    final snapshot = _activeSnapshot;
    if (snapshot == null) return;

    final resolution = resolveSession(
      snapshot,
      state.technique.pattern.cycleDurationMs,
      now(),
    );

    if (resolution.isFinished) {
      await _completeSession(snapshot, now(), emit);
      return;
    }

    emit(
      state.copyWith(
        sessionRemainingSeconds: resolution.remainingSeconds,
        sessionElapsedMs: resolution.elapsedMs,
      ),
    );
  }

  /// Reads any persisted snapshot (falling back to Hive if this bloc
  /// instance was just created, e.g. cold start after the process was
  /// killed) and reconciles the session against real elapsed time. Safe to
  /// dispatch unconditionally — a no-op when there is no session to
  /// reconcile.
  Future<void> _onReconcile(
    ReconcileSession event,
    Emitter<BreathingState> emit,
  ) async {
    final snapshot = _activeSnapshot ?? activeSessionStorage.read();
    if (snapshot == null) return;
    _activeSnapshot = snapshot;

    final technique = BreathingTechniqueCatalog.byId(snapshot.techniqueId);
    final resolution = resolveSession(
      snapshot,
      technique.pattern.cycleDurationMs,
      now(),
    );

    if (resolution.isFinished) {
      await _completeSession(snapshot, now(), emit);
      return;
    }

    _tickerSubscription?.cancel();
    _startTicker();
    if (snapshot.pausedAt != null) {
      _tickerSubscription?.pause();
    }

    emit(
      state.copyWith(
        status: snapshot.pausedAt != null
            ? BreathingStatus.paused
            : BreathingStatus.active,
        technique: technique,
        sessionDurationMinutes: snapshot.sessionDurationMinutes,
        sessionRemainingSeconds: resolution.remainingSeconds,
        sessionElapsedMs: resolution.elapsedMs,
        justReconciled: true,
        selectedReason: snapshot.selectedReason,
        clearSelectedReason: snapshot.selectedReason == null,
      ),
    );
  }

  /// The single, idempotent path a session completes through — reached
  /// either from a foreground tick reaching zero or from reconciliation
  /// discovering the session finished while backgrounded/killed. Guarded by
  /// [hasLoggedSession] so however many times this runs for the same
  /// session id, the completion is only ever recorded once.
  Future<void> _completeSession(
    ActiveSessionSnapshot snapshot,
    DateTime completedAt,
    Emitter<BreathingState> emit,
  ) async {
    _tickerSubscription?.cancel();
    _activeSnapshot = null;
    unawaited(activeSessionStorage.clear());

    if (await hasLoggedSession(snapshot.sessionId)) {
      emit(
        state.copyWith(
          status: BreathingStatus.completed,
          sessionRemainingSeconds: 0,
        ),
      );
      return;
    }

    final technique = BreathingTechniqueCatalog.byId(snapshot.techniqueId);
    final completedDurationSeconds = snapshot.sessionDurationMinutes * 60;
    final startedAt = snapshot.startedAt;
    final sessionId = snapshot.sessionId;
    final dateKeyLocal = dateKeyFor(completedAt.toLocal());

    unawaited(logCompletedSession(completedDurationSeconds));

    // Local progress write is a fast Hive `put` — awaited so the
    // post-session reward below can be computed synchronously and
    // included directly in the emitted state, rather than the page
    // racing a separate fetch against this fire-and-forget write.
    await logProgressSession(
      sessionId: sessionId,
      techniqueId: technique.id,
      techniqueName: technique.name,
      completedDurationSeconds: completedDurationSeconds,
      startedAt: startedAt,
      completedAt: completedAt,
      dateKeyLocal: dateKeyLocal,
      reason: snapshot.selectedReason,
    );
    final reward = await getPostSessionReward();

    emit(
      state.copyWith(
        status: BreathingStatus.completed,
        technique: technique,
        sessionRemainingSeconds: 0,
        sessionElapsedMs: completedDurationSeconds * 1000,
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

    // Firestore mirror stays fire-and-forget, sharing the same
    // client-minted id and dateKey as the local record.
    unawaited(
      logRemoteSession(
        sessionId: sessionId,
        techniqueId: technique.id,
        techniqueName: technique.name,
        durationSeconds: completedDurationSeconds,
        completedDurationSeconds: completedDurationSeconds,
        startedAt: startedAt,
        completedAt: completedAt,
        completed: true,
        dateKeyLocal: dateKeyLocal,
        reason: snapshot.selectedReason,
      ),
    );
  }

  int _secondsFor(int minutes) => minutes == -1 ? -1 : minutes * 60;
}
