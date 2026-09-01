import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:box_breathe/core/services/id_generator.dart';
import 'package:box_breathe/features/breathing/domain/entities/breathing_mode.dart';
import 'package:box_breathe/features/breathing/domain/entities/breathing_settings.dart';
import 'package:box_breathe/features/breathing/domain/usecases/get_breathing_settings.dart';
import 'package:box_breathe/features/breathing/domain/usecases/save_breathing_settings.dart';
import 'package:box_breathe/features/breathing/presentation/bloc/breathing_bloc.dart';
import 'package:box_breathe/features/breathing/presentation/bloc/breathing_event.dart';
import 'package:box_breathe/features/breathing/presentation/bloc/breathing_state.dart';
import 'package:box_breathe/features/history/domain/usecases/log_completed_session.dart';
import 'package:box_breathe/features/history/domain/usecases/log_remote_session.dart';
import 'package:box_breathe/features/progress/domain/entities/post_session_reward.dart';
import 'package:box_breathe/features/progress/domain/usecases/get_post_session_reward.dart';
import 'package:box_breathe/features/progress/domain/usecases/log_progress_session.dart';

class MockGetBreathingSettings extends Mock implements GetBreathingSettings {}

class MockSaveBreathingSettings extends Mock
    implements SaveBreathingSettings {}

class MockLogCompletedSession extends Mock implements LogCompletedSession {}

class MockLogRemoteSession extends Mock implements LogRemoteSession {}

class MockLogProgressSession extends Mock implements LogProgressSession {}

class MockGetPostSessionReward extends Mock implements GetPostSessionReward {}

class MockIdGenerator extends Mock implements IdGenerator {}

class FakeBreathingSettings extends Fake implements BreathingSettings {}

void main() {
  late MockGetBreathingSettings getSettings;
  late MockSaveBreathingSettings saveSettings;
  late MockLogCompletedSession logCompletedSession;
  late MockLogRemoteSession logRemoteSession;
  late MockLogProgressSession logProgressSession;
  late MockGetPostSessionReward getPostSessionReward;
  late MockIdGenerator idGenerator;

  setUpAll(() {
    registerFallbackValue(FakeBreathingSettings());
  });

  setUp(() {
    getSettings = MockGetBreathingSettings();
    saveSettings = MockSaveBreathingSettings();
    logCompletedSession = MockLogCompletedSession();
    logRemoteSession = MockLogRemoteSession();
    logProgressSession = MockLogProgressSession();
    getPostSessionReward = MockGetPostSessionReward();
    idGenerator = MockIdGenerator();

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
    when(() => idGenerator.newId()).thenReturn('test-session-id');
  });

  BreathingBloc buildBloc() => BreathingBloc(
    getSettings: getSettings,
    saveSettings: saveSettings,
    logCompletedSession: logCompletedSession,
    logRemoteSession: logRemoteSession,
    logProgressSession: logProgressSession,
    getPostSessionReward: getPostSessionReward,
    idGenerator: idGenerator,
  );

  group('LoadBreathingSettings', () {
    blocTest<BreathingBloc, BreathingState>(
      'restores the persisted mode and duration (regression: used to '
      'hardcode 3 minutes on every load)',
      setUp: () {
        when(() => getSettings()).thenAnswer(
          (_) async => const Right(
            BreathingSettings(mode: BreathingMode.sleep, durationMinutes: 10),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(LoadBreathingSettings()),
      expect: () => [
        const BreathingState(
          mode: BreathingMode.sleep,
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
            BreathingSettings(mode: BreathingMode.box, durationMinutes: -1),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(LoadBreathingSettings()),
      expect: () => [
        const BreathingState(sessionDurationMinutes: -1, sessionRemainingSeconds: -1),
      ],
    );
  });

  group('ChangeBreathingMode', () {
    blocTest<BreathingBloc, BreathingState>(
      'preserves the currently selected duration instead of resetting to 3 '
      '(regression: used to always reset/save duration as 3)',
      build: buildBloc,
      seed: () => const BreathingState(
        sessionDurationMinutes: 10,
        sessionRemainingSeconds: 600,
      ),
      act: (bloc) => bloc.add(const ChangeBreathingMode(BreathingMode.sleep)),
      expect: () => [
        const BreathingState(
          mode: BreathingMode.sleep,
          sessionDurationMinutes: 10,
          sessionRemainingSeconds: 600,
        ),
      ],
      verify: (_) {
        verify(
          () => saveSettings(
            const BreathingSettings(
              mode: BreathingMode.sleep,
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
              mode: BreathingMode.box,
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

  group('Session ticking', () {
    blocTest<BreathingBloc, BreathingState>(
      'ticks the remaining seconds down while active',
      build: buildBloc,
      seed: () => const BreathingState(
        status: BreathingStatus.active,
        sessionDurationMinutes: 3,
        sessionRemainingSeconds: 3,
      ),
      act: (bloc) => bloc.add(TimerTick()),
      expect: () => [
        const BreathingState(
          status: BreathingStatus.active,
          sessionDurationMinutes: 3,
          sessionRemainingSeconds: 2,
        ),
      ],
    );

    blocTest<BreathingBloc, BreathingState>(
      'never decrements or completes an infinite-duration session',
      build: buildBloc,
      seed: () => const BreathingState(
        status: BreathingStatus.active,
        sessionDurationMinutes: -1,
        sessionRemainingSeconds: -1,
      ),
      act: (bloc) => bloc.add(TimerTick()),
      expect: () => [],
    );

    blocTest<BreathingBloc, BreathingState>(
      'ignores ticks while not active',
      build: buildBloc,
      seed: () => const BreathingState(
        status: BreathingStatus.paused,
        sessionDurationMinutes: 3,
        sessionRemainingSeconds: 60,
      ),
      act: (bloc) => bloc.add(TimerTick()),
      expect: () => [],
    );

    blocTest<BreathingBloc, BreathingState>(
      'reaching zero emits completed exactly once, carries the post-session '
      'reward, and does not auto-revert to initial (regression: used to '
      'double-emit completed then initial in the same handler)',
      build: buildBloc,
      seed: () => const BreathingState(
        status: BreathingStatus.active,
        sessionDurationMinutes: 3,
        sessionRemainingSeconds: 1,
      ),
      act: (bloc) => bloc.add(TimerTick()),
      expect: () => [
        const BreathingState(
          status: BreathingStatus.completed,
          sessionDurationMinutes: 3,
          sessionRemainingSeconds: 0,
          postSessionStreakDays: 1,
        ),
      ],
      verify: (bloc) {
        // Bloc must remain in `completed`, not silently bounce back to
        // `initial` on its own.
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
      seed: () => const BreathingState(status: BreathingStatus.active),
      act: (bloc) => bloc.add(PauseBreathing()),
      expect: () => [const BreathingState(status: BreathingStatus.paused)],
    );

    blocTest<BreathingBloc, BreathingState>(
      'resume transitions status back to active',
      build: buildBloc,
      seed: () => const BreathingState(status: BreathingStatus.paused),
      act: (bloc) => bloc.add(ResumeBreathing()),
      expect: () => [const BreathingState(status: BreathingStatus.active)],
    );
  });

  group('StopBreathing', () {
    blocTest<BreathingBloc, BreathingState>(
      'resets remaining seconds from the current session duration',
      build: buildBloc,
      seed: () => const BreathingState(
        status: BreathingStatus.active,
        sessionDurationMinutes: 5,
        sessionRemainingSeconds: 42,
      ),
      act: (bloc) => bloc.add(StopBreathing()),
      expect: () => [
        const BreathingState(
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
}
