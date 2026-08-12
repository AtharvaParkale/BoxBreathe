import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/premium_controls.dart';
import '../../domain/entities/breathing_mode.dart';

class MomentOption {
  final String label;
  final BreathingMode mode;
  final int durationMinutes;

  const MomentOption({
    required this.label,
    required this.mode,
    required this.durationMinutes,
  });
}

const List<MomentOption> kMomentOptions = [
  MomentOption(
    label: 'Calm down',
    mode: BreathingMode.box,
    durationMinutes: 3,
  ),
  MomentOption(label: 'Relax', mode: BreathingMode.calm, durationMinutes: 5),
  MomentOption(
    label: 'Sleep',
    mode: BreathingMode.sleep,
    durationMinutes: 10,
  ),
  MomentOption(
    label: 'Focus',
    mode: BreathingMode.coherence,
    durationMinutes: 5,
  ),
  MomentOption(
    label: 'Quick reset',
    mode: BreathingMode.quickReset,
    durationMinutes: 1,
  ),
];

/// "What do you need right now?" — a row of need-first shortcuts that
/// jump straight into a matching technique and duration, supplementing
/// (not replacing) the technique-first mode selector.
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
