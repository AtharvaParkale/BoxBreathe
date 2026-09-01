import 'package:equatable/equatable.dart';

/// A locally-persisted mirror of one naturally-completed breathing session,
/// used to compute streaks, calendars, and achievements without needing a
/// network round-trip. Immutable once written — sessions are a log, not
/// editable state.
class ProgressSessionRecord extends Equatable {
  /// Shared with the Firestore doc id, so cross-device sync can dedup by
  /// identity.
  final String id;
  final String techniqueId;
  final String techniqueName;
  final int completedDurationSeconds;
  final DateTime startedAt;
  final DateTime completedAt;

  /// Local-calendar-date key ('yyyy-MM-dd'), frozen at write time — never
  /// re-derived later from a raw timestamp using a possibly different
  /// device timezone.
  final String dateKeyLocal;

  /// Whether the session finished naturally. Defaults to true because only
  /// natural completions have ever been logged historically — aborted
  /// sessions are not currently recorded at all, so every existing record
  /// really was completed. Streak/achievement math filters on this so a
  /// future change to also log aborts can't silently affect them.
  final bool completed;

  /// Why the technique was picked this time (e.g. 'calm', 'sleep'), if the
  /// user arrived via a need-based entry point. Not currently surfaced in
  /// any UI — captured for future personalization.
  final String? reason;

  const ProgressSessionRecord({
    required this.id,
    required this.techniqueId,
    required this.techniqueName,
    required this.completedDurationSeconds,
    required this.startedAt,
    required this.completedAt,
    required this.dateKeyLocal,
    this.completed = true,
    this.reason,
  });

  @override
  List<Object?> get props => [
    id,
    techniqueId,
    techniqueName,
    completedDurationSeconds,
    startedAt,
    completedAt,
    dateKeyLocal,
    completed,
    reason,
  ];
}
