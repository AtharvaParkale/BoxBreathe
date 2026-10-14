import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ease_button.dart';
import '../bloc/breathing_bloc.dart';
import '../bloc/breathing_state.dart';

/// After a session completes: a short acknowledgement, what was done, the
/// streak/achievement line, and two ways on. Stays until dismissed.
class CompletionView extends StatelessWidget {
  final bool hapticsEnabled;
  final VoidCallback onDone;
  final VoidCallback onAgain;

  const CompletionView({
    super.key,
    required this.hapticsEnabled,
    required this.onDone,
    required this.onAgain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return BlocBuilder<BreathingBloc, BreathingState>(
      buildWhen: (a, b) =>
          a.postSessionStreakDays != b.postSessionStreakDays ||
          a.postSessionAchievementTitle != b.postSessionAchievementTitle,
      builder: (context, state) {
        final minutes = state.sessionDurationMinutes;
        final reward = rewardLine(state);
        return Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nicely done.', style: theme.displayMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$minutes minute${minutes == 1 ? '' : 's'} of '
                '${state.technique.name.toLowerCase()}.',
                textAlign: TextAlign.center,
                style: theme.bodyLarge?.copyWith(color: AppColors.secondary),
              ),
              if (reward != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  reward,
                  textAlign: TextAlign.center,
                  style: theme.bodyMedium?.copyWith(color: AppColors.tertiary),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              EaseButton.primary(
                label: 'Done',
                hapticsEnabled: hapticsEnabled,
                onTap: onDone,
              ),
              const SizedBox(height: AppSpacing.sm),
              EaseButton.quiet(
                label: 'Breathe again',
                hapticsEnabled: hapticsEnabled,
                onTap: onAgain,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Achievement beats streak; nothing at all rather than filler copy.
  static String? rewardLine(BreathingState state) {
    final achievement = state.postSessionAchievementTitle;
    if (achievement != null) return 'New achievement — $achievement';
    final days = state.postSessionStreakDays;
    if (days == null) return null;
    if (days <= 1) return 'First day of a new streak';
    return 'Day $days in a row';
  }
}
