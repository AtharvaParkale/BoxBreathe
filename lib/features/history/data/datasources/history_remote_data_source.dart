import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/date_key.dart';
import '../../domain/entities/breathing_session_record.dart';

abstract class HistoryRemoteDataSource {
  /// Writes an append-only session doc under `users/{uid}/sessions/{id}`,
  /// using the caller-provided id (shared with the local progress record)
  /// as the doc id rather than letting Firestore mint its own.
  Future<void> logSession({
    required String uid,
    required BreathingSessionRecord record,
  });

  /// Reads sessions newer than [since] (or all sessions, if null — the same
  /// code path serves both incremental sync and one-time backfill).
  Future<List<BreathingSessionRecord>> getSessionsSince({
    required String uid,
    DateTime? since,
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
        .doc(record.id);

    await docRef.set({
      'techniqueId': record.techniqueId,
      'techniqueName': record.techniqueName,
      'durationSeconds': record.durationSeconds,
      'completedDurationSeconds': record.completedDurationSeconds,
      'startedAt': Timestamp.fromDate(record.startedAt),
      'completedAt': Timestamp.fromDate(record.completedAt),
      'completed': record.completed,
      'dateKeyLocal': record.dateKeyLocal,
      'source': record.source ?? _currentSource(),
    });
  }

  @override
  Future<List<BreathingSessionRecord>> getSessionsSince({
    required String uid,
    DateTime? since,
  }) async {
    Query<Map<String, dynamic>> query = firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('completedAt');

    if (since != null) {
      query = query.where(
        'completedAt',
        isGreaterThan: Timestamp.fromDate(since),
      );
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final completedAt = (data['completedAt'] as Timestamp).toDate();
      return BreathingSessionRecord(
        id: doc.id,
        techniqueId: data['techniqueId'] as String,
        techniqueName: data['techniqueName'] as String,
        durationSeconds: data['durationSeconds'] as int,
        completedDurationSeconds: data['completedDurationSeconds'] as int,
        startedAt: (data['startedAt'] as Timestamp).toDate(),
        completedAt: completedAt,
        completed: data['completed'] as bool,
        // Legacy docs written before this field existed fall back to a
        // best-effort local-timezone derivation — historical data only.
        dateKeyLocal:
            data['dateKeyLocal'] as String? ??
            dateKeyFor(completedAt.toLocal()),
        source: data['source'] as String?,
      );
    }).toList();
  }

  String _currentSource() => Platform.isIOS ? 'ios' : 'android';
}
