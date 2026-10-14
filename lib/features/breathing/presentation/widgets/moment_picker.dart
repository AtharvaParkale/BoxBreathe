import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pressable.dart';
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
    label: 'Sleep',
    techniqueId: 'sleep',
    durationMinutes: BreathingTechniqueCatalog.byId(
      'sleep',
    ).recommendedDuration,
    reason: 'sleep',
  ),
  MomentOption(
    label: 'Focus',
    techniqueId: 'coherence',
    durationMinutes: BreathingTechniqueCatalog.byId(
      'coherence',
    ).recommendedDuration,
    reason: 'focus',
  ),
  MomentOption(
    label: 'Quick reset',
    techniqueId: 'quickReset',
    durationMinutes: BreathingTechniqueCatalog.byId(
      'quickReset',
    ).recommendedDuration,
    reason: 'overwhelmed',
  ),
];

/// "What do you need right now?" — need-first shortcuts that jump straight
/// into a matching technique and duration, set as a quiet line of text
/// under the main action rather than a row of chips.
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
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: AppColors.secondary);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.lg,
      children: [
        for (final option in kMomentOptions)
          Pressable(
            hapticsEnabled: hapticsEnabled,
            semanticLabel: 'Start a ${option.label} session',
            onTap: () => onSelect(option),
            child: Center(
              widthFactor: 1,
              child: Text(option.label, style: style),
            ),
          ),
      ],
    );
  }
}
