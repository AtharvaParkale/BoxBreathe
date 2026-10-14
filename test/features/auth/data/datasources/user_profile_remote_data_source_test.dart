import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:box_breathe/features/auth/data/datasources/user_profile_remote_data_source.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late UserProfileFirestoreDataSourceImpl dataSource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    dataSource = UserProfileFirestoreDataSourceImpl(firestore: firestore);
  });

  test('deleteProfile removes the user doc and all their sessions', () async {
    final user = firestore.collection('users').doc('uid-1');
    await user.set({'provider': 'google'});
    for (var i = 0; i < 3; i++) {
      await user.collection('sessions').doc('s$i').set({'durationSeconds': 60});
    }
    final other = firestore.collection('users').doc('uid-2');
    await other.set({'provider': 'anonymous'});
    await other.collection('sessions').doc('s0').set({'durationSeconds': 60});

    await dataSource.deleteProfile('uid-1');

    expect((await user.get()).exists, isFalse);
    expect((await user.collection('sessions').get()).docs, isEmpty);
    expect((await other.get()).exists, isTrue);
    expect((await other.collection('sessions').get()).docs, hasLength(1));
  });
}
