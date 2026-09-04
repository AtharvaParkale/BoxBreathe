import 'package:hive/hive.dart';

import '../../domain/session_clock.dart';

/// Persists the one in-progress session's [ActiveSessionSnapshot], if any,
/// so a killed-and-relaunched app can reconstruct exactly where a session
/// was. Deliberately unlayered (no repository/usecase split) — same
/// rationale as `OnboardingStorage`: this is transient key-value state, not
/// domain logic. Cleared as soon as a session stops or completes, so a
/// stale snapshot never lingers.
class ActiveSessionStorage {
  final Box box;
  static const String _key = 'active_session_v1';

  ActiveSessionStorage(this.box);

  ActiveSessionSnapshot? read() {
    final raw = box.get(_key);
    if (raw == null) return null;
    final data = Map<String, dynamic>.from(raw as Map);
    final pausedAtMillis = data['pausedAtMillis'] as int?;
    return ActiveSessionSnapshot(
      sessionId: data['sessionId'] as String,
      techniqueId: data['techniqueId'] as String,
      sessionDurationMinutes: data['sessionDurationMinutes'] as int,
      selectedReason: data['selectedReason'] as String?,
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        data['startedAtMillis'] as int,
      ),
      pausedAt: pausedAtMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(pausedAtMillis),
      accumulatedPauseMs: data['accumulatedPauseMs'] as int,
    );
  }

  Future<void> save(ActiveSessionSnapshot snapshot) {
    return box.put(_key, {
      'sessionId': snapshot.sessionId,
      'techniqueId': snapshot.techniqueId,
      'sessionDurationMinutes': snapshot.sessionDurationMinutes,
      'selectedReason': snapshot.selectedReason,
      'startedAtMillis': snapshot.startedAt.millisecondsSinceEpoch,
      'pausedAtMillis': snapshot.pausedAt?.millisecondsSinceEpoch,
      'accumulatedPauseMs': snapshot.accumulatedPauseMs,
    });
  }

  Future<void> clear() => box.delete(_key);
}
