import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/breathing_session_record.dart';

abstract class HistoryRemoteDataSource {
  /// Writes an append-only session doc under `users/{uid}/sessions/{auto}`.
  Future<void> logSession({
    required String uid,
    required BreathingSessionRecord record,
  });
}

class FirestoreHistoryRemoteDataSourceImpl implements HistoryRemoteDataSource {
  final FirebaseFirestore firestore;

  FirestoreHistoryRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> logSession({
    required String uid,
    required BreathingSessionRecord record,
  }) async {
    final docRef = firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc();

    await docRef.set({
      'techniqueId': record.techniqueId,
      'techniqueName': record.techniqueName,
      'durationSeconds': record.durationSeconds,
      'completedDurationSeconds': record.completedDurationSeconds,
      'startedAt': Timestamp.fromDate(record.startedAt),
      'completedAt': Timestamp.fromDate(record.completedAt),
      'completed': record.completed,
      'source': record.source ?? _currentSource(),
    });
  }

  String _currentSource() => Platform.isIOS ? 'ios' : 'android';
}
