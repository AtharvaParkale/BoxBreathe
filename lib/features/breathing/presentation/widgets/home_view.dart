import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ease_button.dart';
import '../../../../core/widgets/pressable.dart';
import '../bloc/breathing_bloc.dart';
import '../bloc/breathing_state.dart';
import 'moment_picker.dart';

/// "4 min" / "No limit" — the one place durations are spelled out.
String formatDurationChoice(int minutes) =>
    minutes == -1 ? 'No limit' : '$minutes min';

/// Home top row: the wordmark, then quiet text links to the library and
/// progress, and settings.
class HomeHeader extends StatelessWidget {
  final bool hapticsEnabled;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenProgress;
  final VoidCallback onOpenSettings;

  const HomeHeader({
    super.key,
    required this.hapticsEnabled,
    required this.onOpenLibrary,
    required this.onOpenProgress,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final link = theme.bodyMedium?.copyWith(color: AppColors.secondary);

    Widget textLink(String label, VoidCallback onTap) => Pressable(
      hapticsEnabled: hapticsEnabled,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Center(widthFactor: 1, child: Text(label, style: link)),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.gutter,
        right: AppSpacing.md,
      ),
      child: Row(
        children: [
          ExcludeSemantics(child: Text('Ease', style: theme.headlineSmall)),
          const Spacer(),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  textLink('Techniques', onOpenLibrary),
                  textLink('Progress', onOpenProgress),
                  Pressable(
                    hapticsEnabled: hapticsEnabled,
                    semanticLabel: 'Settings',
                    onTap: onOpenSettings,
                    child: const Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Idle stage under the orb: the invitation, what will play and for how
/// long (each tappable), the one primary action, and need shortcuts.
class HomeView extends StatelessWidget {
  final bool hapticsEnabled;
  final VoidCallback onBegin;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenDuration;
  final ValueChanged<MomentOption> onSelectMoment;

  const HomeView({
    super.key,
    required this.hapticsEnabled,
    required this.onBegin,
    required this.onOpenLibrary,
    required this.onOpenDuration,
    required this.onSelectMoment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final selection = theme.bodyLarge?.copyWith(
      color: AppColors.secondary,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.disabled,
      decorationThickness: 1,
    );

    return BlocBuilder<BreathingBloc, BreathingState>(
      buildWhen: (a, b) =>
          a.technique != b.technique ||
          a.sessionDurationMinutes != b.sessionDurationMinutes,
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Breathe.',
              style: theme.displayLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Pressable(
                  hapticsEnabled: hapticsEnabled,
                  semanticLabel:
                      'Technique: ${state.technique.name}. Change technique',
                  onTap: onOpenLibrary,
                  child: Center(
                    widthFactor: 1,
                    child: Text(state.technique.name, style: selection),
                  ),
                ),
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      '·',
                      style: theme.bodyLarge?.copyWith(
                        color: AppColors.tertiary,
                      ),
                    ),
                  ),
                ),
                Pressable(
                  hapticsEnabled: hapticsEnabled,
                  semanticLabel:
                      'Duration: ${formatDurationChoice(state.sessionDurationMinutes)}. Change duration',
                  onTap: onOpenDuration,
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      formatDurationChoice(state.sessionDurationMinutes),
                      style: selection,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            EaseButton.primary(
              label: 'Begin',
              semanticLabel: 'Begin session',
              hapticsEnabled: hapticsEnabled,
              onTap: onBegin,
            ),
            const SizedBox(height: AppSpacing.md),
            MomentPicker(
              hapticsEnabled: hapticsEnabled,
              onSelect: onSelectMoment,
            ),
          ],
        );
      },
    );
  }
}
