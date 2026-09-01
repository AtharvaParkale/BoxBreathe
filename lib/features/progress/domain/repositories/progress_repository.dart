import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/post_session_reward.dart';
import '../entities/progress_session_record.dart';
import '../entities/progress_summary.dart';

abstract class ProgressRepository {
  /// Local-only write, always fast and offline-safe.
  Future<Either<Failure, void>> logSession(ProgressSessionRecord record);

  /// Local-only read of the current summary — fast, no network dependency.
  /// [forMonth] only affects `monthlyPracticeCounts` (the calendar section);
  /// everything else always reflects the real current date.
  Future<Either<Failure, ProgressSummary>> getSummary({DateTime? forMonth});

  /// Pulls remote sessions newer than the locally-stored per-uid cursor,
  /// merges them (deduped by id) into the local session log, and advances
  /// the cursor to the max `completedAt` actually observed — never to
  /// `DateTime.now()`, so a lagging device clock can't cause a session to
  /// permanently fall through the sync window. Returns the number of newly
  /// merged records.
  Future<Either<Failure, int>> syncFromRemote();

  /// Called right after logging a session: computes the live streak and
  /// checks every achievement definition, persisting (and returning) at
  /// most one newly-crossed achievement.
  Future<Either<Failure, PostSessionReward>> evaluatePostSessionReward();
}
