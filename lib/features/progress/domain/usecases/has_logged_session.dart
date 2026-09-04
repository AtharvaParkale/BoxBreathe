import '../repositories/progress_repository.dart';

/// Idempotency guard for session completion recording — used both when a
/// session finishes in the foreground and when reconciliation discovers it
/// finished while backgrounded/killed, so a completion is never logged
/// twice no matter how many times reconciliation runs.
class HasLoggedSession {
  final ProgressRepository repository;

  HasLoggedSession(this.repository);

  Future<bool> call(String sessionId) {
    return repository.hasLoggedSession(sessionId);
  }
}
