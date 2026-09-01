import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:box_breathe/core/utils/date_key.dart';
import 'package:box_breathe/features/history/data/datasources/history_remote_data_source.dart';
import 'package:box_breathe/features/history/domain/entities/breathing_session_record.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreHistoryRemoteDataSourceImpl dataSource;

  const uid = 'uid-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    dataSource = FirestoreHistoryRemoteDataSourceImpl(firestore: firestore);
  });

  BreathingSessionRecord buildRecord({
    required String id,
    required DateTime completedAt,
  }) => BreathingSessionRecord(
    id: id,
    techniqueId: 'box',
    techniqueName: 'Box',
    durationSeconds: 180,
    completedDurationSeconds: 180,
    startedAt: completedAt.subtract(const Duration(minutes: 3)),
    completedAt: completedAt,
    completed: true,
    dateKeyLocal: dateKeyFor(completedAt),
    source: 'android',
  );

  test('logSession writes under the caller-provided id, not an auto id', () async {
    final record = buildRecord(id: 'client-id-1', completedAt: DateTime(2026, 9, 2));
    await dataSource.logSession(uid: uid, record: record);

    final doc = await firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc('client-id-1')
        .get();

    expect(doc.exists, isTrue);
    expect(doc.data()!['dateKeyLocal'], '2026-09-02');
  });

  test('getSessionsSince orders by completedAt and respects the cursor', () async {
    await dataSource.logSession(
      uid: uid,
      record: buildRecord(id: 'old', completedAt: DateTime(2026, 9, 1)),
    );
    await dataSource.logSession(
      uid: uid,
      record: buildRecord(id: 'new', completedAt: DateTime(2026, 9, 3)),
    );

    final all = await dataSource.getSessionsSince(uid: uid);
    expect(all.map((r) => r.id).toList(), ['old', 'new']);

    final sinceOnlyNew = await dataSource.getSessionsSince(
      uid: uid,
      since: DateTime(2026, 9, 2),
    );
    expect(sinceOnlyNew.map((r) => r.id).toList(), ['new']);
  });

  test(
    'falls back to deriving dateKeyLocal from completedAt for legacy docs '
    'written before the field existed',
    () async {
      final completedAt = DateTime(2026, 9, 2, 10, 30);
      await firestore
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .doc('legacy')
          .set({
            'techniqueId': 'box',
            'techniqueName': 'Box',
            'durationSeconds': 180,
            'completedDurationSeconds': 180,
            'startedAt': Timestamp.fromDate(
              completedAt.subtract(const Duration(minutes: 3)),
            ),
            'completedAt': Timestamp.fromDate(completedAt),
            'completed': true,
            'source': 'android',
            // no dateKeyLocal field
          });

      final records = await dataSource.getSessionsSince(uid: uid);
      expect(records.single.dateKeyLocal, dateKeyFor(completedAt.toLocal()));
    },
  );
}
