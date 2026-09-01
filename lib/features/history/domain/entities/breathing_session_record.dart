import 'package:equatable/equatable.dart';

class BreathingSessionRecord extends Equatable {
  /// Shared with the local progress record and used as the Firestore doc
  /// id, so a session logged locally and mirrored remotely can be deduped
  /// by identity during cross-device sync.
  final String id;
  final String techniqueId;
  final String techniqueName;
  final int durationSeconds;
  final int completedDurationSeconds;
  final DateTime startedAt;
  final DateTime completedAt;
  final bool completed;

  /// Local-calendar-date key ('yyyy-MM-dd'), frozen at write time on the
  /// completing device — never re-derived later from a raw timestamp.
  final String dateKeyLocal;

  /// Device platform ('android' | 'ios'). Left null by callers — the remote
  /// data source fills it in at write time, since it's a device property,
  /// not something the breathing session logic should need to know.
  final String? source;

  /// Why the technique was picked this time (e.g. 'calm', 'sleep'), if the
  /// user arrived via a need-based entry point. Captured for future
  /// personalization, not currently surfaced in any UI.
  final String? reason;

  const BreathingSessionRecord({
    required this.id,
    required this.techniqueId,
    required this.techniqueName,
    required this.durationSeconds,
    required this.completedDurationSeconds,
    required this.startedAt,
    required this.completedAt,
    required this.completed,
    required this.dateKeyLocal,
    this.source,
    this.reason,
  });

  @override
  List<Object?> get props => [
    id,
    techniqueId,
    techniqueName,
    durationSeconds,
    completedDurationSeconds,
    startedAt,
    completedAt,
    completed,
    dateKeyLocal,
    source,
    reason,
  ];
}
