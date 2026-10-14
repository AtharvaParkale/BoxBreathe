import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/ease_page.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/lists.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../injection_container.dart' as di;
import '../../../breathing/domain/entities/breathing_technique_catalog.dart';
import '../../domain/entities/achievement_progress.dart';
import '../../domain/entities/progress_session_record.dart';
import '../../domain/entities/progress_summary.dart';
import '../../domain/entities/streak_info.dart';
import '../../domain/usecases/get_recent_sessions.dart';
import '../bloc/progress_bloc.dart';
import '../bloc/progress_event.dart';
import '../bloc/progress_state.dart';
import '../widgets/day_of_week_row.dart';
import '../widgets/month_calendar_grid.dart';

/// Pops with `true` from the empty state's Begin, so home can start a
/// session straight away.
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

class _ProgressView extends StatefulWidget {
  const _ProgressView();

  @override
  State<_ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<_ProgressView> {
  late final Future<List<ProgressSessionRecord>> _recentFuture = di
      .sl<GetRecentSessions>()(limit: 10)
      .then(
        (result) =>
            result.fold((_) => const <ProgressSessionRecord>[], (s) => s),
      );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressBloc, ProgressState>(
      builder: (context, state) {
        final summary = state.summary;
        return EasePage(
          title: 'Progress',
          slivers: [
            GutterSliver(
              child: AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.calm),
                child: summary == null
                    ? const _Skeleton()
                    : summary.lifetime.totalSessions == 0
                    ? _empty(context, summary)
                    : _content(context, state, summary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _empty(BuildContext context, ProgressSummary summary) {
    return Column(
      key: const ValueKey('empty'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmptyState(
          title: 'Nothing here yet.',
          body:
              'Finish your first session and your streak, minutes and '
              'history will start to fill in here.',
          actionLabel: 'Begin a session',
          onAction: () => Navigator.pop(context, true),
        ),
        const SectionLabel('Achievements'),
        _achievements(context, summary.achievements),
      ],
    );
  }

  Widget _content(
    BuildContext context,
    ProgressState state,
    ProgressSummary summary,
  ) {
    return Column(
      key: const ValueKey('content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StreakHero(streak: summary.streak),

        const SectionLabel('This week'),
        const SizedBox(height: AppSpacing.sm),
        DayOfWeekRow(
          perDayPracticed: summary.thisWeek.perDayPracticed,
          todayIndex: DateTime.now().weekday - 1,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '${summary.thisWeek.sessionsThisWeek} '
          'session${summary.thisWeek.sessionsThisWeek == 1 ? '' : 's'} · '
          '${formatMinutes(summary.thisWeek.minutesThisWeek)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        const SectionLabel('All time'),
        _StatStrip(lifetime: summary.lifetime),

        const SectionLabel('Calendar'),
        _MonthHeader(month: state.displayedMonth),
        const SizedBox(height: AppSpacing.sm),
        MonthCalendarGrid(
          month: state.displayedMonth,
          practiceCounts: summary.monthlyPracticeCounts,
        ),

        FutureBuilder<List<ProgressSessionRecord>>(
          future: _recentFuture,
          builder: (context, snapshot) {
            final recent = snapshot.data ?? const [];
            if (recent.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionLabel('Recent sessions'),
                HairlineList(
                  children: [
                    for (final r in recent)
                      ListRow(
                        title: BreathingTechniqueCatalog.exists(r.techniqueId)
                            ? BreathingTechniqueCatalog.byId(r.techniqueId).name
                            : r.techniqueName,
                        subtitle: formatRelativeDay(r.completedAt),
                        value: formatMinutes(r.completedDurationSeconds ~/ 60),
                      ),
                  ],
                ),
              ],
            );
          },
        ),

        if (summary.byTechnique.isNotEmpty) ...[
          const SectionLabel('By technique'),
          for (final e in summary.byTechnique) _TechniqueShare(entry: e),
        ],

        const SectionLabel('Records'),
        HairlineList(
          children: [
            ListRow(
              title: 'Longest streak',
              value:
                  '${summary.personalRecords.longestStreakDays} '
                  'day${summary.personalRecords.longestStreakDays == 1 ? '' : 's'}',
            ),
            ListRow(
              title: 'Longest session',
              value: formatMinutes(
                summary.personalRecords.longestSessionMinutes,
              ),
            ),
            ListRow(
              title: 'Most in one day',
              value:
                  '${summary.personalRecords.mostSessionsInOneDay} '
                  'session${summary.personalRecords.mostSessionsInOneDay == 1 ? '' : 's'}',
            ),
          ],
        ),

        const SectionLabel('Achievements'),
        _achievements(context, summary.achievements),
      ],
    );
  }

  Widget _achievements(BuildContext context, List<AchievementProgress> all) {
    final earned = all.where((a) => a.unlocked).toList();
    final ahead = all.where((a) => !a.unlocked).toList();
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (earned.isNotEmpty)
          HairlineList(
            children: [
              for (final a in earned)
                ListRow(
                  title: a.definition.title,
                  subtitle:
                      'Earned ${formatRelativeDay(a.unlockedAt!).toLowerCase()}',
                  trailing: const Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: AppColors.white,
                  ),
                ),
            ],
          ),
        if (earned.isNotEmpty && ahead.isNotEmpty) const Divider(),
        if (ahead.isNotEmpty)
          HairlineList(
            children: [
              for (final a in ahead)
                ListRow(
                  title: a.definition.title,
                  titleStyle: theme.bodyLarge?.copyWith(
                    color: AppColors.secondary,
                  ),
                  subtitle: a.definition.description,
                  value: '${_num(a.current)}/${_num(a.definition.threshold)}',
                ),
            ],
          ),
      ],
    );
  }

  static String _num(num n) => n == n.roundToDouble() ? '${n.round()}' : '$n';
}

class _StreakHero extends StatelessWidget {
  final StreakInfo streak;

  const _StreakHero({required this.streak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final String subline;
    if (streak.current == 0) {
      subline = 'Your next streak starts with one session.';
    } else if (!streak.isActiveToday) {
      subline = 'Breathe today to keep it going.';
    } else if (streak.longest > streak.current) {
      subline = 'Your longest is ${streak.longest} days.';
    } else {
      subline = 'Your longest yet.';
    }

    return Semantics(
      label: '${streak.current} day streak. $subline',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${streak.current}', style: AppTypography.heroNumeral),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'day${streak.current == 1 ? '' : 's'} in a row',
                  style: theme.bodyLarge?.copyWith(color: AppColors.secondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(subline, style: theme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Three figures side by side, hairline above and below — no cards.
class _StatStrip extends StatelessWidget {
  final LifetimeStats lifetime;

  const _StatStrip({required this.lifetime});

  @override
  Widget build(BuildContext context) {
    final minutes = formatMinutes(lifetime.totalMinutes);
    final stats = [
      (minutes, 'practiced'),
      ('${lifetime.totalSessions}', 'sessions'),
      ('${lifetime.totalDaysPracticed}', 'days'),
    ];
    final theme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.hairline),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                color: AppColors.hairline,
              ),
            Expanded(
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(stats[i].$1, style: theme.headlineSmall),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(stats[i].$2, style: theme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;

  const _MonthHeader({required this.month});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final atCurrentMonth =
        month.year > now.year ||
        (month.year == now.year && month.month >= now.month);
    final bloc = context.read<ProgressBloc>();

    return Row(
      children: [
        Expanded(
          child: Text(
            formatMonthYear(month),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Pressable(
          semanticLabel: 'Previous month',
          onTap: () => bloc.add(
            ChangeDisplayedMonth(DateTime(month.year, month.month - 1)),
          ),
          child: const Icon(
            Icons.chevron_left_rounded,
            color: AppColors.secondary,
          ),
        ),
        Pressable(
          semanticLabel: 'Next month',
          onTap: atCurrentMonth
              ? null
              : () => bloc.add(
                  ChangeDisplayedMonth(DateTime(month.year, month.month + 1)),
                ),
          child: Icon(
            Icons.chevron_right_rounded,
            color: atCurrentMonth ? AppColors.disabled : AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class _TechniqueShare extends StatelessWidget {
  final TechniqueBreakdownEntry entry;

  const _TechniqueShare({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final percent = (entry.percentage * 100).round();
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(entry.techniqueName, style: theme.bodyLarge),
                ),
                Text(
                  '$percent%',
                  style: theme.bodyLarge?.copyWith(
                    color: AppColors.secondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ExcludeSemantics(
              child: LayoutBuilder(
                builder: (context, c) => Stack(
                  children: [
                    Container(height: 2, color: AppColors.hairline),
                    Container(
                      height: 2,
                      width: c.maxWidth * entry.percentage.clamp(0.0, 1.0),
                      color: AppColors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quiet placeholder while the local summary loads (usually a frame or
/// two) — shapes, not a spinner.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: AppColors.faint,
    );
    return Semantics(
      label: 'Loading progress',
      child: Column(
        key: const ValueKey('skeleton'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(96, 64),
          bar(200, 14),
          const SizedBox(height: AppSpacing.huge),
          bar(double.infinity, 24),
          bar(double.infinity, 24),
          bar(double.infinity, 24),
        ],
      ),
    );
  }
}
