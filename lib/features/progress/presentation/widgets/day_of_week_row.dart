import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Monday..Sunday: a filled disc where a session was completed, a hairline
/// ring otherwise. Today is marked by its label (white, not dimmed) and a
/// brighter ring — never by colour alone.
class DayOfWeekRow extends StatelessWidget {
  final List<bool> perDayPracticed; // Mon..Sun
  final int todayIndex; // 0=Mon..6=Sun

  const DayOfWeekRow({
    super.key,
    required this.perDayPracticed,
    required this.todayIndex,
  });

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _fullNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.bodySmall;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final practiced = perDayPracticed[i];
        final isToday = i == todayIndex;
        return Semantics(
          label:
              '${_fullNames[i]}: ${practiced ? 'practiced' : 'not practiced'}'
              '${isToday ? ', today' : ''}',
          child: ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: practiced ? AppColors.white : Colors.transparent,
                    border: Border.all(
                      color: practiced
                          ? AppColors.white
                          : (isToday
                                ? AppColors.secondary
                                : AppColors.hairline),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _labels[i],
                  style: label?.copyWith(
                    color: isToday ? AppColors.white : AppColors.tertiary,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
