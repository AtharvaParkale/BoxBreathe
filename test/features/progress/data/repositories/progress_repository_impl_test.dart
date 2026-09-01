import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:box_breathe/core/utils/date_key.dart';
import 'package:box_breathe/features/auth/domain/entities/user_profile.dart';
import 'package:box_breathe/features/auth/domain/repositories/auth_repository.dart';
import 'package:box_breathe/features/history/domain/entities/breathing_session_record.dart';
import 'package:box_breathe/features/history/domain/usecases/get_sessions_since.dart';
import 'package:box_breathe/features/progress/data/datasources/progress_local_data_source.dart';
import 'package:box_breathe/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:box_breathe/features/progress/domain/entities/progress_session_record.dart';

class MockProgressLocalDataSource extends Mock
    implements ProgressLocalDataSource {}

class MockGetSessionsSince extends Mock implements GetSessionsSince {}

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeProgressSessionRecord extends Fake implements ProgressSessionRecord {}

void main() {
  late MockProgressLocalDataSource localDataSource;
  late MockGetSessionsSince getSessionsSince;
  late MockAuthRepository authRepository;
  late ProgressRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(FakeProgressSessionRecord());
  });

  setUp(() {
    localDataSource = MockProgressLocalDataSource();
    getSessionsSince = MockGetSessionsSince();
    authRepository = MockAuthRepository();
    repository = ProgressRepositoryImpl(
      localDataSource: localDataSource,
      getSessionsSince: getSessionsSince,
      authRepository: authRepository,
    );

    when(() => localDataSource.putSession(any())).thenAnswer((_) async {});
    when(
      () => localDataSource.markAchievementUnlocked(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => localDataSource.getAchievementUnlockedAt(any()),
    ).thenReturn(null);
  });

  UserProfile buildUser(String uid) => UserProfile(
    uid: uid,
    provider: AuthProviderType.anonymous,
    createdAt: DateTime(2026, 1, 1),
    lastActiveAt: DateTime(2026, 1, 1),
  );

  ProgressSessionRecord buildLocal(String id, String dateKey, {int seconds = 180}) =>
      ProgressSessionRecord(
        id: id,
        techniqueId: 'box',
        techniqueName: 'Box',
        completedDurationSeconds: seconds,
        startedAt: DateTime.parse('${dateKey}T09:00:00'),
        completedAt: DateTime.parse('${dateKey}T09:03:00'),
        dateKeyLocal: dateKey,
      );

  BreathingSessionRecord buildRemote(String id, String dateKey, DateTime completedAt) =>
      BreathingSessionRecord(
        id: id,
        techniqueId: 'sleep',
        techniqueName: 'Sleep',
        durationSeconds: 300,
        completedDurationSeconds: 300,
        startedAt: completedAt.subtract(const Duration(minutes: 5)),
        completedAt: completedAt,
        completed: true,
        dateKeyLocal: dateKey,
      );

  group('logSession', () {
    test('delegates to the local data source', () async {
      final record = buildLocal('s1', '2026-09-02');
      final result = await repository.logSession(record);
      expect(result, const Right<Object, void>(null));
      verify(() => localDataSource.putSession(record)).called(1);
    });
  });

  group('getSummary', () {
    test('computes lifetime totals and streak from local records', () async {
      when(() => localDataSource.getAllSessions()).thenReturn([
        buildLocal('s1', '2026-09-01'),
        buildLocal('s2', '2026-09-02'),
      ]);

      final result = await repository.getSummary(
        forMonth: DateTime(2026, 9, 15),
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (summary) {
        expect(summary.lifetime.totalSessions, 2);
        expect(summary.lifetime.totalMinutes, 6);
        expect(summary.lifetime.totalDaysPracticed, 2);
      });
    });
  });

  group('syncFromRemote', () {
    test('no-ops when uid has not resolved yet', () async {
      when(() => authRepository.currentUser).thenReturn(null);

      final result = await repository.syncFromRemote();

      expect(result, const Right<Object, int>(0));
      verifyNever(() => getSessionsSince(since: any(named: 'since')));
    });

    test(
      'merges only unseen remote records and advances the cursor to the '
      'max observed completedAt, not DateTime.now()',
      () async {
        when(() => authRepository.currentUser).thenReturn(buildUser('uid-a'));
        when(() => localDataSource.getLastSyncedMillis('uid-a')).thenReturn(null);
        when(() => localDataSource.hasSession('r1')).thenReturn(false);
        when(() => localDataSource.hasSession('r2')).thenReturn(true);
        when(
          () => localDataSource.setLastSyncedMillis(any(), any()),
        ).thenAnswer((_) async {});

        final laterCompletedAt = DateTime(2026, 9, 2, 10, 0);
        final earlierCompletedAt = DateTime(2026, 9, 1, 10, 0);
        when(() => getSessionsSince(since: null)).thenAnswer(
          (_) async => Right([
            buildRemote('r2', '2026-09-01', earlierCompletedAt),
            buildRemote('r1', '2026-09-02', laterCompletedAt),
          ]),
        );

        final result = await repository.syncFromRemote();

        expect(result, const Right<Object, int>(1));
        verify(() => localDataSource.putSession(any())).called(1);
        verify(
          () => localDataSource.setLastSyncedMillis(
            'uid-a',
            laterCompletedAt.millisecondsSinceEpoch,
          ),
        ).called(1);
      },
    );

    test('resumes from the stored per-uid cursor on subsequent syncs', () async {
      when(() => authRepository.currentUser).thenReturn(buildUser('uid-a'));
      final cursorMillis = DateTime(2026, 9, 1).millisecondsSinceEpoch;
      when(() => localDataSource.getLastSyncedMillis('uid-a')).thenReturn(cursorMillis);
      when(() => getSessionsSince(since: any(named: 'since'))).thenAnswer(
        (_) async => const Right([]),
      );

      await repository.syncFromRemote();

      final captured = verify(
        () => getSessionsSince(since: captureAny(named: 'since')),
      ).captured;
      expect(captured.single, DateTime.fromMillisecondsSinceEpoch(cursorMillis));
    });
  });

  group('evaluatePostSessionReward', () {
    test(
      'reports the live current streak and persists a newly-crossed '
      'achievement exactly once',
      () async {
        final todayKey = dateKeyFor(DateTime.now());
        when(() => localDataSource.getAllSessions()).thenReturn([
          buildLocal('s1', todayKey),
        ]);

        final result = await repository.evaluatePostSessionReward();

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('expected Right'), (reward) {
          expect(reward.streakDays, 1);
          expect(reward.newlyUnlockedTitle, 'First Breath');
        });
        verify(
          () => localDataSource.markAchievementUnlocked('first_session', any()),
        ).called(1);
      },
    );

    test('does not re-persist an achievement that is already unlocked', () async {
      when(() => localDataSource.getAllSessions()).thenReturn([
        buildLocal('s1', dateKeyFor(DateTime.now())),
      ]);
      when(
        () => localDataSource.getAchievementUnlockedAt('first_session'),
      ).thenReturn(DateTime(2026, 8, 1));

      final result = await repository.evaluatePostSessionReward();

      result.fold((_) => fail('expected Right'), (reward) {
        expect(reward.newlyUnlockedTitle, isNull);
      });
      verifyNever(
        () => localDataSource.markAchievementUnlocked('first_session', any()),
      );
    });
  });
}
