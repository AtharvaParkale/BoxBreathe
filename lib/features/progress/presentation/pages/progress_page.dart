import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_containers.dart';
import '../../../../core/widgets/premium_controls.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/achievement_progress.dart';
import '../../domain/entities/progress_summary.dart';
import '../../domain/entities/streak_info.dart';
import '../bloc/progress_bloc.dart';
import '../bloc/progress_event.dart';
import '../bloc/progress_state.dart';
import '../widgets/day_of_week_row.dart';
import '../widgets/month_calendar_grid.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ProgressBloc>()..add(LoadProgress()),
      child: const _ProgressView(),
    );
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<ProgressBloc, ProgressState>(
        builder: (context, state) {
          final summary = state.summary;
          if (state.isLoading || summary == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final isEmpty = summary.lifetime.totalSessions == 0;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const SizedBox(height: AppSpacing.md),
              _buildHero(context, summary.streak),
              const SizedBox(height: AppSpacing.xxl),

              if (!isEmpty) ...[
                const AppSectionHeader(title: 'LIFETIME'),
                const SizedBox(height: AppSpacing.sm2),
                _buildLifetime(context, summary.lifetime),
                const SizedBox(height: AppSpacing.xxl),

                const AppSectionHeader(title: 'THIS WEEK'),
                const SizedBox(height: AppSpacing.sm2),
                _buildThisWeek(context, summary.thisWeek),
                const SizedBox(height: AppSpacing.xxl),

                const AppSectionHeader(title: 'THIS MONTH'),
                const SizedBox(height: AppSpacing.sm2),
                _buildThisMonth(
                  context,
                  state.displayedMonth,
                  summary.monthlyPracticeCounts,
                ),
                const SizedBox(height: AppSpacing.xxl),

                if (summary.byTechnique.isNotEmpty) ...[
                  const AppSectionHeader(title: 'BY TECHNIQUE'),
                  const SizedBox(height: AppSpacing.sm2),
                  _buildByTechnique(context, summary.byTechnique),
                  const SizedBox(height: AppSpacing.xxl),
                ],

                const AppSectionHeader(title: 'PERSONAL RECORDS'),
                const SizedBox(height: AppSpacing.sm2),
                _buildPersonalRecords(context, summary.personalRecords),
                const SizedBox(height: AppSpacing.xxl),
              ],

              const AppSectionHeader(title: 'ACHIEVEMENTS'),
              const SizedBox(height: AppSpacing.sm2),
              _buildAchievements(context, summary.achievements),
              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHero(BuildContext context, StreakInfo streak) {
    final theme = Theme.of(context);
    final String subline;
    if (streak.current == 0) {
      subline = 'Your next streak starts today.';
    } else if (!streak.isActiveToday) {
      subline = 'Practice today to keep it going.';
    } else if (streak.longest > streak.current) {
      subline = 'Longest: ${streak.longest} days';
    } else {
      subline =
          "You've shown up ${streak.current} "
          "day${streak.current == 1 ? '' : 's'} in a row.";
    }

    return Semantics(
      label: '${streak.current} day streak. $subline',
      child: ExcludeSemantics(
        child: Center(
          child: Column(
            children: [
              Text('${streak.current}', style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text('DAY STREAK', style: theme.textTheme.labelSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subline,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLifetime(BuildContext context, LifetimeStats lifetime) {
    return AppGroupContainer(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          title: Text(_formatMinutes(lifetime.totalMinutes)),
          subtitle: const Text('Total practice'),
        ),
        const AppDivider(),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          title: Text('${lifetime.totalSessions}'),
          subtitle: Text(
            'Session${lifetime.totalSessions == 1 ? '' : 's'} completed',
          ),
        ),
        const AppDivider(),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          title: Text('${lifetime.totalDaysPracticed}'),
          subtitle: Text(
            'Day${lifetime.totalDaysPracticed == 1 ? '' : 's'} practiced',
          ),
        ),
      ],
    );
  }

  Widget _buildThisWeek(BuildContext context, WeekSummary week) {
    final todayIndex = DateTime.now().weekday - 1;
    return AppGroupContainer(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: DayOfWeekRow(
            perDayPracticed: week.perDayPracticed,
            todayIndex: todayIndex,
          ),
        ),
        const AppDivider(),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          title: Text(
            '${week.sessionsThisWeek} '
            'session${week.sessionsThisWeek == 1 ? '' : 's'}',
          ),
          subtitle: Text('${_formatMinutes(week.minutesThisWeek)} practiced'),
        ),
      ],
    );
  }

  Widget _buildThisMonth(
    BuildContext context,
    DateTime displayedMonth,
    Map<int, int> counts,
  ) {
    final atCurrentMonth = _isAtOrAfterCurrentMonth(displayedMonth);
    return AppGroupContainer(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PremiumIconButton(
                icon: Icons.chevron_left_rounded,
                size: 36,
                semanticLabel: 'Previous month',
                onTap: () => context.read<ProgressBloc>().add(
                  ChangeDisplayedMonth(
                    DateTime(displayedMonth.year, displayedMonth.month - 1),
                  ),
                ),
              ),
              Text(
                _formatMonthYear(displayedMonth),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              PremiumIconButton(
                icon: Icons.chevron_right_rounded,
                size: 36,
                semanticLabel: 'Next month',
                onTap: atCurrentMonth
                    ? null
                    : () => context.read<ProgressBloc>().add(
                        ChangeDisplayedMonth(
                          DateTime(
                            displayedMonth.year,
                            displayedMonth.month + 1,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: MonthCalendarGrid(month: displayedMonth, practiceCounts: counts),
        ),
      ],
    );
  }

  Widget _buildByTechnique(
    BuildContext context,
    List<TechniqueBreakdownEntry> entries,
  ) {
    final theme = Theme.of(context);
    return AppGroupContainer(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const AppDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entries[i].techniqueName, style: theme.textTheme.bodyLarge),
                    Text(
                      '${(entries[i].percentage * 100).round()}%',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: entries[i].percentage,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPersonalRecords(BuildContext context, PersonalRecords records) {
    return AppGroupContainer(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          title: Text(
            '${records.longestStreakDays} '
            'day${records.longestStreakDays == 1 ? '' : 's'}',
          ),
          subtitle: const Text('Longest streak'),
        ),
        const AppDivider(),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          title: Text('${records.longestSessionMinutes} min'),
          subtitle: const Text('Longest session'),
        ),
        const AppDivider(),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          title: Text('${records.mostSessionsInOneDay}'),
          subtitle: const Text('Most sessions in one day'),
        ),
      ],
    );
  }

  Widget _buildAchievements(
    BuildContext context,
    List<AchievementProgress> achievements,
  ) {
    return AppGroupContainer(
      children: [
        for (var i = 0; i < achievements.length; i++) ...[
          if (i > 0) const AppDivider(),
          _buildAchievementRow(context, achievements[i]),
        ],
      ],
    );
  }

  Widget _buildAchievementRow(BuildContext context, AchievementProgress p) {
    final theme = Theme.of(context);
    final def = p.definition;
    final dimAlpha = p.unlocked ? 1.0 : 0.35;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      title: Text(
        def.title,
        style: TextStyle(
          fontWeight: p.unlocked ? FontWeight.w600 : FontWeight.w400,
          color: p.unlocked
              ? null
              : theme.colorScheme.onSurface.withValues(alpha: dimAlpha),
        ),
      ),
      subtitle: Text(
        p.unlocked
            ? 'Unlocked ${_formatRelativeDate(p.unlockedAt!)}'
            : '${def.description} · ${p.current}/${def.threshold}',
        style: TextStyle(
          color: theme.colorScheme.onSurface.withValues(
            alpha: p.unlocked ? 0.6 : dimAlpha,
          ),
        ),
      ),
      trailing: p.unlocked
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : Icon(
              Icons.circle_outlined,
              size: 24,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
    );
  }

  bool _isAtOrAfterCurrentMonth(DateTime month) {
    final now = DateTime.now();
    return month.year > now.year ||
        (month.year == now.year && month.month >= now.month);
  }

  String _formatMinutes(int totalMinutes) {
    if (totalMinutes < 60) return '$totalMinutes min';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
  }

  String _formatMonthYear(DateTime d) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${names[d.month - 1]} ${d.year}';
  }

  String _formatRelativeDate(DateTime d) {
    final now = DateTime.now();
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    return '$days days ago';
  }
}
