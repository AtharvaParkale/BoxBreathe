import 'package:equatable/equatable.dart';

/// Never persisted — recomputed live from the full local session set every
/// time. Because the underlying record set only ever grows and is never
/// mutated, [longest] is mathematically guaranteed to never regress; no
/// stored "best ever" counter is needed.
class StreakInfo extends Equatable {
  final int current;
  final int longest;
  final String? lastPracticedDateKey;

  /// True if today's dateKey is already in the practiced set.
  final bool isActiveToday;

  const StreakInfo({
    required this.current,
    required this.longest,
    required this.lastPracticedDateKey,
    required this.isActiveToday,
  });

  static const empty = StreakInfo(
    current: 0,
    longest: 0,
    lastPracticedDateKey: null,
    isActiveToday: false,
  );

  @override
  List<Object?> get props => [
    current,
    longest,
    lastPracticedDateKey,
    isActiveToday,
  ];
}
