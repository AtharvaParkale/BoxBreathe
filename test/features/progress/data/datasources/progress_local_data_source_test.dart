import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:box_breathe/features/progress/data/datasources/progress_local_data_source.dart';
import 'package:box_breathe/features/progress/domain/entities/progress_session_record.dart';

void main() {
  late Directory tempDir;
  late Box sessionsBox;
  late Box achievementsBox;
  late Box metaBox;
  late ProgressLocalDataSourceImpl dataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('progress_local_test');
    Hive.init(tempDir.path);
    sessionsBox = await Hive.openBox('progress_sessions_test');
    achievementsBox = await Hive.openBox('progress_achievements_test');
    metaBox = await Hive.openBox('progress_meta_test');
    dataSource = ProgressLocalDataSourceImpl(
      sessionsBox: sessionsBox,
      achievementsBox: achievementsBox,
      metaBox: metaBox,
    );
  });

  tearDown(() async {
    await sessionsBox.deleteFromDisk();
    await achievementsBox.deleteFromDisk();
    await metaBox.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  ProgressSessionRecord buildRecord(String id) => ProgressSessionRecord(
    id: id,
    techniqueId: 'box',
    techniqueName: 'Box',
    completedDurationSeconds: 180,
    startedAt: DateTime(2026, 9, 2, 9, 0),
    completedAt: DateTime(2026, 9, 2, 9, 3),
    dateKeyLocal: '2026-09-02',
  );

  test('putSession then getAllSessions round-trips a record', () async {
    final record = buildRecord('session-1');
    await dataSource.putSession(record);

    final all = dataSource.getAllSessions();
    expect(all, hasLength(1));
    expect(all.first, record);
  });

  test('hasSession reflects prior writes for dedup checks', () async {
    expect(dataSource.hasSession('session-1'), isFalse);
    await dataSource.putSession(buildRecord('session-1'));
    expect(dataSource.hasSession('session-1'), isTrue);
  });

  test('putSession is idempotent when the same id is written twice', () async {
    await dataSource.putSession(buildRecord('session-1'));
    await dataSource.putSession(buildRecord('session-1'));
    expect(dataSource.getAllSessions(), hasLength(1));
  });

  test('achievement unlock timestamps persist and read back', () async {
    expect(dataSource.getAchievementUnlockedAt('streak_7'), isNull);
    final now = DateTime(2026, 9, 2, 12, 0);
    await dataSource.markAchievementUnlocked('streak_7', now);
    expect(dataSource.getAchievementUnlockedAt('streak_7'), now);
  });

  test('last-synced cursor is stored per-uid', () async {
    expect(dataSource.getLastSyncedMillis('uid-a'), isNull);
    await dataSource.setLastSyncedMillis('uid-a', 1000);
    await dataSource.setLastSyncedMillis('uid-b', 2000);
    expect(dataSource.getLastSyncedMillis('uid-a'), 1000);
    expect(dataSource.getLastSyncedMillis('uid-b'), 2000);
  });
}
