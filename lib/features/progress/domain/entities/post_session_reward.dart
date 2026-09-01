import 'package:equatable/equatable.dart';

/// A one-line reward shown for 3 seconds on the breathing page's completed
/// state. [newlyUnlockedTitle] takes priority over [streakDays] when both
/// are present — an achievement unlock is the more meaningful moment.
class PostSessionReward extends Equatable {
  final int streakDays;
  final String? newlyUnlockedTitle;

  const PostSessionReward({
    required this.streakDays,
    required this.newlyUnlockedTitle,
  });

  @override
  List<Object?> get props => [streakDays, newlyUnlockedTitle];
}
