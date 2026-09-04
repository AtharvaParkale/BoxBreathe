import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:box_breathe/core/services/id_generator.dart';
import 'package:box_breathe/features/breathing/data/datasources/active_session_storage.dart';
import 'package:box_breathe/features/breathing/domain/entities/breathing_technique_catalog.dart';
import 'package:box_breathe/features/breathing/domain/entities/breathing_settings.dart';
import 'package:box_breathe/features/breathing/domain/session_clock.dart';
import 'package:box_breathe/features/breathing/domain/usecases/get_breathing_settings.dart';
import 'package:box_breathe/features/breathing/domain/usecases/save_breathing_settings.dart';
import 'package:box_breathe/features/breathing/presentation/bloc/breathing_bloc.dart';
import 'package:box_breathe/features/breathing/presentation/bloc/breathing_event.dart';
import 'package:box_breathe/features/breathing/presentation/bloc/breathing_state.dart';
import 'package:box_breathe/features/history/domain/usecases/log_completed_session.dart';
import 'package:box_breathe/features/history/domain/usecases/log_remote_session.dart';
import 'package:box_breathe/features/progress/domain/entities/post_session_reward.dart';
import 'package:box_breathe/features/progress/domain/usecases/get_post_session_reward.dart';
import 'package:box_breathe/features/progress/domain/usecases/has_logged_session.dart';
import 'package:box_breathe/features/progress/domain/usecases/log_progress_session.dart';

class MockGetBreathingSettings extends Mock implements GetBreathingSettings {}

class MockSaveBreathingSettings extends Mock
    implements SaveBreathingSettings {}

class MockLogCompletedSession extends Mock implements LogCompletedSession {}

class MockLogRemoteSession extends Mock implements LogRemoteSession {}

class MockLogProgressSession extends Mock implements LogProgressSession {}

class MockGetPostSessionReward extends Mock implements GetPostSessionReward {}

class MockHasLoggedSession extends Mock implements HasLoggedSession {}

class MockIdGenerator extends Mock implements IdGenerator {}

class MockActiveSessionStorage extends Mock implements ActiveSessionStorage {}

class FakeBreathingSettings extends Fake implements BreathingSettings {}

class FakeActiveSessionSnapshot extends Fake implements ActiveSessionSnapshot {}

void main() {
  late MockGetBreathingSettings getSettings;
  late MockSaveBreathingSettings saveSettings;
  late MockLogCompletedSession logCompletedSession;
  late MockLogRemoteSession logRemoteSession;
  late MockLogProgressSession logProgressSession;
  late MockGetPostSessionReward getPostSessionReward;
  late MockHasLoggedSession hasLoggedSession;
  late MockIdGenerator idGenerator;
  late MockActiveSessionStorage activeSessionStorage;

  // Fully controllable clock — lets tests fast-forward through a session
  // instantly instead of waiting on real seconds, and is what makes
  // background/reconciliation scenarios (which are all "a lot of real time
  // passed with nothing ticking") testable at all.
  late DateTime fakeNow;
  DateTime now() => fakeNow;

  // Bloc event handlers run asynchronously relative to `bloc.add(...)` — a
  // synchronous `act` callback that mutates `fakeNow` right after `add()`
  // would race ahead of the handler and advance the clock before it ever
  // reads `startedAt`/`now()`. Yielding a turn lets a (non-suspending)
  // handler actually run first.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUpAll(() {
    registerFallbackValue(FakeBreathingSettings());
    registerFallbackValue(FakeActiveSessionSnapshot());
  });

  setUp(() {
    fakeNow = DateTime(2026, 1, 1, 12, 0, 0);
    getSettings = MockGetBreathingSettings();
    saveSettings = MockSaveBreathingSettings();
    logCompletedSession = MockLogCompletedSession();
    logRemoteSession = MockLogRemoteSession();
    logProgressSession = MockLogProgressSession();
    getPostSessionReward = MockGetPostSessionReward();
    hasLoggedSession = MockHasLoggedSession();
    idGenerator = MockIdGenerator();
    activeSessionStorage = MockActiveSessionStorage();

    when(
      () => saveSettings(any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => logCompletedSession(any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => logRemoteSession(
        sessionId: any(named: 'sessionId'),
        techniqueId: any(named: 'techniqueId'),
        techniqueName: any(named: 'techniqueName'),
        durationSeconds: any(named: 'durationSeconds'),
        completedDurationSeconds: any(named: 'completedDurationSeconds'),
        startedAt: any(named: 'startedAt'),
        completedAt: any(named: 'completedAt'),
        completed: any(named: 'completed'),
        dateKeyLocal: any(named: 'dateKeyLocal'),
      ),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => logProgressSession(
        sessionId: any(named: 'sessionId'),
        techniqueId: any(named: 'techniqueId'),
        techniqueName: any(named: 'techniqueName'),
        completedDurationSeconds: any(named: 'completedDurationSeconds'),
        startedAt: any(named: 'startedAt'),
        completedAt: any(named: 'completedAt'),
        dateKeyLocal: any(named: 'dateKeyLocal'),
      ),
    ).thenAnswer((_) async => const Right(null));
    when(() => getPostSessionReward()).thenAnswer(
      (_) async => const Right(
        PostSessionReward(streakDays: 1, newlyUnlockedTitle: null),
      ),
    );
    when(() => hasLoggedSession(any())).thenAnswer((_) async => false);
    when(() => idGenerator.newId()).thenReturn('test-session-id');
    when(() => activeSessionStorage.read()).thenReturn(null);
    when(() => activeSessionStorage.save(any())).thenAnswer((_) async {});
    when(() => activeSessionStorage.clear()).thenAnswer((_) async {});
  });

  BreathingBloc buildBloc() => BreathingBloc(
    getSettings: getSettings,
    saveSettings: saveSettings,
    logCompletedSession: logCompletedSession,
    logRemoteSession: logRemoteSession,
    logProgressSession: logProgressSession,
    getPostSessionReward: getPostSessionReward,
    hasLoggedSession: hasLoggedSession,
    idGenerator: idGenerator,
    activeSessionStorage: activeSessionStorage,
    now: now,
  );

  group('LoadBreathingSettings', () {
    blocTest<BreathingBloc, BreathingState>(
      'restores the persisted mode and duration (regression: used to '
      'hardcode 3 minutes on every load)',
      setUp: () {
        when(() => getSettings()).thenAnswer(
          (_) async => const Right(
            BreathingSettings(techniqueId: 'sleep', durationMinutes: 10),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(LoadBreathingSettings()),
      expect: () => [
        BreathingState(
          technique: BreathingTechniqueCatalog.byId('sleep'),
          sessionDurationMinutes: 10,
          sessionRemainingSeconds: 600,
        ),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'restores an infinite persisted duration correctly',
      setUp: () {
        when(() => getSettings()).thenAnswer(
          (_) async => const Right(
            BreathingSettings(techniqueId: 'box', durationMinutes: -1),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(LoadBreathingSettings()),
      expect: () => [
        BreathingState(sessionDurationMinutes: -1, sessionRemainingSeconds: -1),
      ],
    );
  });

  group('ChangeTechnique', () {
    blocTest<BreathingBloc, BreathingState>(
      'preserves the currently selected duration instead of resetting to 3 '
      '(regression: used to always reset/save duration as 3)',
      build: buildBloc,
      seed: () => BreathingState(
        sessionDurationMinutes: 10,
        sessionRemainingSeconds: 600,
      ),
      act: (bloc) => bloc.add(const ChangeTechnique('sleep')),
      expect: () => [
        BreathingState(
          technique: BreathingTechniqueCatalog.byId('sleep'),
          sessionDurationMinutes: 10,
          sessionRemainingSeconds: 600,
        ),
      ],
      verify: (_) {
        verify(
          () => saveSettings(
            const BreathingSettings(
              techniqueId: 'sleep',
              durationMinutes: 10,
            ),
          ),
        ).called(1);
      },
    );
  });

  group('ChangeSessionDuration', () {
    blocTest<BreathingBloc, BreathingState>(
      'persists the new duration (regression: used to never save it)',
      build: buildBloc,
      act: (bloc) => bloc.add(const ChangeSessionDuration(10)),
      verify: (_) {
        verify(
          () => saveSettings(
            const BreathingSettings(
              techniqueId: 'box',
              durationMinutes: 10,
            ),
          ),
        ).called(1);
      },
    );

    blocTest<BreathingBloc, BreathingState>(
      'updates the session duration and remaining seconds',
      build: buildBloc,
      act: (bloc) => bloc.add(const ChangeSessionDuration(10)),
      verify: (bloc) {
        expect(bloc.state.sessionDurationMinutes, 10);
        expect(bloc.state.sessionRemainingSeconds, 600);
        expect(bloc.state.status, BreathingStatus.initial);
      },
    );
  });

  group('Session ticking (timestamp-driven)', () {
    blocTest<BreathingBloc, BreathingState>(
      'ticks the remaining seconds down using real elapsed time, not a '
      'decrement',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(StartBreathing());
        await settle();
        fakeNow = fakeNow.add(const Duration(seconds: 60));
        bloc.add(TimerTick());
      },
      expect: () => [
        BreathingState(
          status: BreathingStatus.active,
          sessionDurationMinutes: 3,
          sessionRemainingSeconds: 180,
        ),
        BreathingState(
          status: BreathingStatus.active,
          sessionDurationMinutes: 3,
          sessionRemainingSeconds: 120,
          sessionElapsedMs: 60000,
        ),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'never completes an infinite-duration session no matter how much '
      'time passes',
      build: buildBloc,
      seed: () => BreathingState(
        sessionDurationMinutes: -1,
        sessionRemainingSeconds: -1,
      ),
      act: (bloc) async {
        bloc.add(StartBreathing());
        await settle();
        fakeNow = fakeNow.add(const Duration(days: 1));
        bloc.add(TimerTick());
      },
      verify: (bloc) {
        expect(bloc.state.status, BreathingStatus.active);
        expect(bloc.state.sessionRemainingSeconds, -1);
      },
    );

    blocTest<BreathingBloc, BreathingState>(
      'ignores ticks while not active',
      build: buildBloc,
      seed: () => BreathingState(
        status: BreathingStatus.paused,
        sessionDurationMinutes: 3,
        sessionRemainingSeconds: 60,
      ),
      act: (bloc) => bloc.add(TimerTick()),
      expect: () => [],
    );

    blocTest<BreathingBloc, BreathingState>(
      'reaching zero real elapsed time emits completed exactly once, '
      'carries the post-session reward, and does not auto-revert to '
      'initial (regression: used to double-emit completed then initial)',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(StartBreathing());
        await settle();
        fakeNow = fakeNow.add(const Duration(minutes: 3));
        bloc.add(TimerTick());
      },
      expect: () => [
        BreathingState(
          status: BreathingStatus.active,
          sessionDurationMinutes: 3,
          sessionRemainingSeconds: 180,
        ),
        BreathingState(
          status: BreathingStatus.completed,
          sessionDurationMinutes: 3,
          sessionRemainingSeconds: 0,
          sessionElapsedMs: 180000,
          postSessionStreakDays: 1,
        ),
      ],
      verify: (bloc) {
        expect(bloc.state.status, BreathingStatus.completed);
        verify(() => idGenerator.newId()).called(1);
        verify(
          () => logProgressSession(
            sessionId: 'test-session-id',
            techniqueId: any(named: 'techniqueId'),
            techniqueName: any(named: 'techniqueName'),
            completedDurationSeconds: any(named: 'completedDurationSeconds'),
            startedAt: any(named: 'startedAt'),
            completedAt: any(named: 'completedAt'),
            dateKeyLocal: any(named: 'dateKeyLocal'),
          ),
        ).called(1);
        verify(
          () => logRemoteSession(
            sessionId: 'test-session-id',
            techniqueId: any(named: 'techniqueId'),
            techniqueName: any(named: 'techniqueName'),
            durationSeconds: any(named: 'durationSeconds'),
            completedDurationSeconds: any(named: 'completedDurationSeconds'),
            startedAt: any(named: 'startedAt'),
            completedAt: any(named: 'completedAt'),
            completed: any(named: 'completed'),
            dateKeyLocal: any(named: 'dateKeyLocal'),
          ),
        ).called(1);
      },
    );
  });

  group('Pause / Resume', () {
    blocTest<BreathingBloc, BreathingState>(
      'pause transitions status to paused',
      build: buildBloc,
      seed: () => BreathingState(status: BreathingStatus.active),
      act: (bloc) => bloc.add(PauseBreathing()),
      expect: () => [BreathingState(status: BreathingStatus.paused)],
    );

    blocTest<BreathingBloc, BreathingState>(
      'resume transitions status back to active',
      build: buildBloc,
      seed: () => BreathingState(status: BreathingStatus.paused),
      act: (bloc) => bloc.add(ResumeBreathing()),
      expect: () => [BreathingState(status: BreathingStatus.active)],
    );

    blocTest<BreathingBloc, BreathingState>(
      'time spent paused does not count toward elapsed session time',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(StartBreathing()); // t=0
        await settle();
        fakeNow = fakeNow.add(const Duration(seconds: 10));
        bloc.add(PauseBreathing()); // paused after 10s of real elapsed
        await settle();
        fakeNow = fakeNow.add(const Duration(seconds: 50)); // 50s while paused
        bloc.add(ResumeBreathing());
        await settle();
        fakeNow = fakeNow.add(const Duration(seconds: 20)); // 20s more elapsed
        bloc.add(TimerTick());
      },
      verify: (bloc) {
        // Real elapsed = 10s (before pause) + 20s (after resume) = 30s —
        // the 50s spent paused must not count, even though 80s of
        // wall-clock time passed in total.
        expect(bloc.state.sessionRemainingSeconds, 180 - 30);
      },
    );
  });

  group('StopBreathing', () {
    blocTest<BreathingBloc, BreathingState>(
      'resets remaining seconds from the current session duration',
      build: buildBloc,
      seed: () => BreathingState(
        status: BreathingStatus.active,
        sessionDurationMinutes: 5,
        sessionRemainingSeconds: 42,
      ),
      act: (bloc) => bloc.add(StopBreathing()),
      expect: () => [
        BreathingState(
          sessionDurationMinutes: 5,
          sessionRemainingSeconds: 300,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => logRemoteSession(
            sessionId: any(named: 'sessionId'),
            techniqueId: any(named: 'techniqueId'),
            techniqueName: any(named: 'techniqueName'),
            durationSeconds: any(named: 'durationSeconds'),
            completedDurationSeconds: any(named: 'completedDurationSeconds'),
            startedAt: any(named: 'startedAt'),
            completedAt: any(named: 'completedAt'),
            completed: any(named: 'completed'),
            dateKeyLocal: any(named: 'dateKeyLocal'),
          ),
        );
        verifyNever(
          () => logProgressSession(
            sessionId: any(named: 'sessionId'),
            techniqueId: any(named: 'techniqueId'),
            techniqueName: any(named: 'techniqueName'),
            completedDurationSeconds: any(named: 'completedDurationSeconds'),
            startedAt: any(named: 'startedAt'),
            completedAt: any(named: 'completedAt'),
            dateKeyLocal: any(named: 'dateKeyLocal'),
          ),
        );
      },
    );
  });

  group('ReconcileSession', () {
    blocTest<BreathingBloc, BreathingState>(
      'no-ops when there is no persisted session to reconcile',
      build: buildBloc,
      act: (bloc) => bloc.add(ReconcileSession()),
      expect: () => [],
    );

    blocTest<BreathingBloc, BreathingState>(
      'a session still in progress is restored with recomputed remaining '
      'time and flagged for the UI to re-anchor its animation',
      setUp: () {
        when(() => activeSessionStorage.read()).thenReturn(
          ActiveSessionSnapshot(
            sessionId: 'bg-session-id',
            techniqueId: 'box',
            sessionDurationMinutes: 3,
            selectedReason: null,
            startedAt: fakeNow.subtract(const Duration(seconds: 30)),
            pausedAt: null,
            accumulatedPauseMs: 0,
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ReconcileSession()),
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.status, 'status', BreathingStatus.active)
            .having(
              (s) => s.sessionRemainingSeconds,
              'sessionRemainingSeconds',
              150,
            )
            .having((s) => s.justReconciled, 'justReconciled', isTrue),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'a session that finished while backgrounded is completed exactly '
      'once',
      setUp: () {
        when(() => activeSessionStorage.read()).thenReturn(
          ActiveSessionSnapshot(
            sessionId: 'bg-session-id',
            techniqueId: 'box',
            sessionDurationMinutes: 3,
            selectedReason: null,
            startedAt: fakeNow.subtract(const Duration(minutes: 5)),
            pausedAt: null,
            accumulatedPauseMs: 0,
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ReconcileSession()),
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.status, 'status', BreathingStatus.completed)
            .having(
              (s) => s.sessionRemainingSeconds,
              'sessionRemainingSeconds',
              0,
            ),
      ],
      verify: (_) {
        verify(
          () => logProgressSession(
            sessionId: 'bg-session-id',
            techniqueId: any(named: 'techniqueId'),
            techniqueName: any(named: 'techniqueName'),
            completedDurationSeconds: any(named: 'completedDurationSeconds'),
            startedAt: any(named: 'startedAt'),
            completedAt: any(named: 'completedAt'),
            dateKeyLocal: any(named: 'dateKeyLocal'),
          ),
        ).called(1);
      },
    );

    blocTest<BreathingBloc, BreathingState>(
      'reconciling an already-recorded completion does not log it again '
      '(covers reopening the app multiple times after a background '
      'completion)',
      setUp: () {
        when(() => activeSessionStorage.read()).thenReturn(
          ActiveSessionSnapshot(
            sessionId: 'bg-session-id',
            techniqueId: 'box',
            sessionDurationMinutes: 3,
            selectedReason: null,
            startedAt: fakeNow.subtract(const Duration(minutes: 5)),
            pausedAt: null,
            accumulatedPauseMs: 0,
          ),
        );
        when(
          () => hasLoggedSession('bg-session-id'),
        ).thenAnswer((_) async => true);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ReconcileSession()),
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.status, 'status', BreathingStatus.completed),
      ],
      verify: (_) {
        verifyNever(
          () => logProgressSession(
            sessionId: any(named: 'sessionId'),
            techniqueId: any(named: 'techniqueId'),
            techniqueName: any(named: 'techniqueName'),
            completedDurationSeconds: any(named: 'completedDurationSeconds'),
            startedAt: any(named: 'startedAt'),
            completedAt: any(named: 'completedAt'),
            dateKeyLocal: any(named: 'dateKeyLocal'),
          ),
        );
        verifyNever(
          () => logRemoteSession(
            sessionId: any(named: 'sessionId'),
            techniqueId: any(named: 'techniqueId'),
            techniqueName: any(named: 'techniqueName'),
            durationSeconds: any(named: 'durationSeconds'),
            completedDurationSeconds: any(named: 'completedDurationSeconds'),
            startedAt: any(named: 'startedAt'),
            completedAt: any(named: 'completedAt'),
            completed: any(named: 'completed'),
            dateKeyLocal: any(named: 'dateKeyLocal'),
          ),
        );
      },
    );

    blocTest<BreathingBloc, BreathingState>(
      'a paused session stays paused after reconciling, with elapsed time '
      'frozen at the moment it was paused',
      setUp: () {
        when(() => activeSessionStorage.read()).thenReturn(
          ActiveSessionSnapshot(
            sessionId: 'bg-session-id',
            techniqueId: 'box',
            sessionDurationMinutes: 3,
            selectedReason: null,
            startedAt: fakeNow.subtract(const Duration(minutes: 10)),
            pausedAt: fakeNow.subtract(const Duration(minutes: 9, seconds: 45)),
            accumulatedPauseMs: 0,
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ReconcileSession()),
      expect: () => [
        isA<BreathingState>()
            .having((s) => s.status, 'status', BreathingStatus.paused)
            .having(
              (s) => s.sessionRemainingSeconds,
              'sessionRemainingSeconds',
              165,
            ),
      ],
    );
  });
}
