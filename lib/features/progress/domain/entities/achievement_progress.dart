import 'package:equatable/equatable.dart';

import 'achievement_definition.dart';

/// Runtime view of an achievement for the UI. Only [unlockedAt] is
/// persisted (once, the first time it's observed true) — [current] and
/// [unlocked] are recomputed live every time from the local session set.
class AchievementProgress extends Equatable {
  final AchievementDefinition definition;
  final num current;
  final bool unlocked;
  final DateTime? unlockedAt;

  const AchievementProgress({
    required this.definition,
    required this.current,
    required this.unlocked,
    required this.unlockedAt,
  });

  @override
  List<Object?> get props => [definition, current, unlocked, unlockedAt];
}
