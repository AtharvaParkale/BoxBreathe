import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';

/// One month as a Monday-first grid of dots: white where you practised,
/// faint where you didn't, today ringed.
class MonthCalendarGrid extends StatelessWidget {
  final DateTime month;
  final Map<int, int> practiceCounts;

  const MonthCalendarGrid({
    super.key,
    required this.month,
    required this.practiceCounts,
  });

  static const _weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.bodySmall;
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmpty = firstOfMonth.weekday - 1;

    final now = DateTime.now();
    final isCurrentMonth = now.year == month.year && now.month == month.month;
    final monthName = formatMonthYear(month).split(' ').first;

    final cells = <Widget>[
      for (final d in _weekdayInitials)
        ExcludeSemantics(
          child: Center(child: Text(d, style: label)),
        ),
      for (var i = 0; i < leadingEmpty; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _Day(
          practiced: (practiceCounts[day] ?? 0) > 0,
          isToday: isCurrentMonth && now.day == day,
          semanticLabel: '$monthName $day',
        ),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.xs,
      childAspectRatio: 1.2,
      children: cells,
    );
  }
}

class _Day extends StatelessWidget {
  final bool practiced;
  final bool isToday;
  final String semanticLabel;

  const _Day({
    required this.practiced,
    required this.isToday,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '$semanticLabel: ${practiced ? 'practiced' : 'not practiced'}'
          '${isToday ? ', today' : ''}',
      child: ExcludeSemantics(
        child: Center(
          child: Container(
            width: isToday ? 16 : 8,
            height: isToday ? 16 : 8,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isToday ? Border.all(color: AppColors.secondary) : null,
            ),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: practiced ? AppColors.white : AppColors.hairline,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
