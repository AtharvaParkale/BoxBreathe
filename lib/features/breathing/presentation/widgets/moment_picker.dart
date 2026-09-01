import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/premium_controls.dart';
import '../../domain/entities/breathing_technique_catalog.dart';

class MomentOption {
  final String label;
  final String techniqueId;
  final int durationMinutes;
  final String? reason;

  const MomentOption({
    required this.label,
    required this.techniqueId,
    required this.durationMinutes,
    this.reason,
  });
}

final List<MomentOption> kMomentOptions = [
  MomentOption(
    label: 'Calm down',
    techniqueId: 'box',
    durationMinutes: BreathingTechniqueCatalog.byId('box').recommendedDuration,
    reason: 'calm',
  ),
  MomentOption(
    label: 'Relax',
    techniqueId: 'calm478',
    durationMinutes:
        BreathingTechniqueCatalog.byId('calm478').recommendedDuration,
    reason: 'calm',
  ),
  MomentOption(
    label: 'Sleep',
    techniqueId: 'sleep',
    durationMinutes:
        BreathingTechniqueCatalog.byId('sleep').recommendedDuration,
    reason: 'sleep',
  ),
  MomentOption(
    label: 'Focus',
    techniqueId: 'coherence',
    durationMinutes:
        BreathingTechniqueCatalog.byId('coherence').recommendedDuration,
    reason: 'focus',
  ),
  MomentOption(
    label: 'Quick reset',
    techniqueId: 'quickReset',
    durationMinutes:
        BreathingTechniqueCatalog.byId('quickReset').recommendedDuration,
    reason: 'overwhelmed',
  ),
];

/// "What do you need right now?" — a row of need-first shortcuts that
/// jump straight into a matching technique and duration, supplementing
/// (not replacing) the full technique library.
class MomentPicker extends StatelessWidget {
  final ValueChanged<MomentOption> onSelect;
  final bool hapticsEnabled;

  const MomentPicker({
    super.key,
    required this.onSelect,
    this.hapticsEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: kMomentOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final option = kMomentOptions[index];
          return Semantics(
            button: true,
            label: 'Start a ${option.label} session',
            child: PremiumScaleButton(
              hapticsEnabled: hapticsEnabled,
              onTap: () => onSelect(option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: 0.14,
                    ),
                    width: 1,
                  ),
                ),
                child: Text(
                  option.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
