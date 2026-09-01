import 'package:flutter/material.dart';

/// Minimal monochrome dot-per-day grid for one month — no drill-down tap
/// targets (deferred). [month] may be any date within the displayed month.
class MonthCalendarGrid extends StatelessWidget {
  final DateTime month;
  final Map<int, int> practiceCounts;

  const MonthCalendarGrid({
    super.key,
    required this.month,
    required this.practiceCounts,
  });

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmpty = firstOfMonth.weekday - 1; // Monday-first grid

    final now = DateTime.now();
    final isCurrentMonth = now.year == month.year && now.month == month.month;

    final cells = <Widget>[
      for (var i = 0; i < leadingEmpty; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _buildDay(theme, day, isCurrentMonth && now.day == day),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      children: cells,
    );
  }

  Widget _buildDay(ThemeData theme, int day, bool isToday) {
    final practiced = (practiceCounts[day] ?? 0) > 0;
    final size = isToday ? 14.0 : 10.0;
    return Semantics(
      label:
          '${_monthNames[month.month - 1]} $day: '
          '${practiced ? 'practiced' : 'not practiced'}',
      child: ExcludeSemantics(
        child: Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: practiced
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.10),
              border: isToday
                  ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
