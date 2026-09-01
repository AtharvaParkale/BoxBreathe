import 'package:flutter/material.dart';

/// Monday..Sunday row of 7 small monochrome ticks — filled where a session
/// was completed that day, hollow otherwise. Today gets a hairline ring so
/// it's identifiable regardless of fill state — no information conveyed by
/// color alone.
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
    final theme = Theme.of(context);
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: practiced
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: isToday
                          ? theme.colorScheme.primary.withValues(alpha: 0.9)
                          : theme.colorScheme.onSurface.withValues(
                              alpha: 0.14,
                            ),
                      width: isToday ? 1.5 : 1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _labels[i],
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
