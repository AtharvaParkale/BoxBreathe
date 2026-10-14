import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/breathing_pattern.dart';

/// One breathing cycle drawn roughly to scale: each phase gets width
/// proportional to its duration (with a floor so very short phases stay
/// legible), distinguished by tone (inhale brightest, exhale
/// softer, holds faint) and labelled underneath — the rhythm you'll follow,
/// readable at a glance.
class RhythmBar extends StatelessWidget {
  final BreathingPattern pattern;

  const RhythmBar({super.key, required this.pattern});

  static Color _tone(BreathingPhaseKind kind) => switch (kind) {
    BreathingPhaseKind.inhale => AppColors.white,
    BreathingPhaseKind.exhale => AppColors.secondary,
    BreathingPhaseKind.hold => AppColors.disabled,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final minFlex = (pattern.cycleDurationMs * 0.2).round();
    final description = pattern.segments
        .map((s) => '${s.label} ${formatPhaseSeconds(s.durationMs)} seconds')
        .join(', ');

    return Semantics(
      label: 'One cycle: $description',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < pattern.segments.length; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                flex: pattern.segments[i].durationMs < minFlex
                    ? minFlex
                    : pattern.segments[i].durationMs,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 3,
                      color: _tone(pattern.segments[i].kind),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _sentenceCase(pattern.segments[i].label),
                        style: theme.bodySmall?.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${formatPhaseSeconds(pattern.segments[i].durationMs)}s',
                        style: theme.labelMedium?.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _sentenceCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}
