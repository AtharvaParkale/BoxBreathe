import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_containers.dart';
import '../../../../core/widgets/premium_controls.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_event_state.dart';
import '../../domain/entities/breathing_technique.dart';
import '../../domain/entities/breathing_technique_catalog.dart';
import '../bloc/breathing_bloc.dart';
import '../bloc/breathing_event.dart';
import '../widgets/phase_breakdown_row.dart';

class TechniqueDetailPage extends StatefulWidget {
  final BreathingTechnique technique;

  /// Carried through if the user arrived via a need-based entry point
  /// (e.g. a "What do you need right now?" category), for session
  /// analytics — not shown in the UI.
  final String? reason;

  const TechniqueDetailPage({
    super.key,
    required this.technique,
    this.reason,
  });

  @override
  State<TechniqueDetailPage> createState() => _TechniqueDetailPageState();
}

class _TechniqueDetailPageState extends State<TechniqueDetailPage> {
  late int _selectedDuration = widget.technique.recommendedDuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final technique = widget.technique;
    final hapticsEnabled = context.select(
      (SettingsBloc bloc) => bloc.state.settings.isHapticEnabled,
    );
    final isFavorite = context.select(
      (SettingsBloc bloc) =>
          bloc.state.settings.favoriteTechniqueIds.contains(technique.id),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: PremiumIconButton(
              icon: isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: 40,
              hapticsEnabled: hapticsEnabled,
              semanticLabel: isFavorite
                  ? 'Remove from favorites'
                  : 'Add to favorites',
              onTap: () => context.read<SettingsBloc>().add(
                ToggleFavoriteTechnique(technique.id),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          140,
        ),
        children: [
          Text(
            technique.name,
            style: theme.textTheme.displayMedium?.copyWith(fontSize: 26),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DifficultyPill(difficulty: technique.difficulty),
          const SizedBox(height: AppSpacing.md),
          Text(technique.shortDescription, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.xxl),

          const AppSectionHeader(title: 'WHAT IT HELPS WITH'),
          const SizedBox(height: AppSpacing.sm2),
          _ChipWrap(items: technique.benefits),
          const SizedBox(height: AppSpacing.xxl),

          const AppSectionHeader(title: 'WHEN TO USE IT'),
          const SizedBox(height: AppSpacing.sm2),
          AppGroupContainer(children: _bulletRows(technique.useCases)),
          const SizedBox(height: AppSpacing.xxl),

          const AppSectionHeader(title: 'HOW IT WORKS'),
          const SizedBox(height: AppSpacing.sm2),
          PhaseBreakdownRow(pattern: technique.pattern),
          const SizedBox(height: AppSpacing.xxl),

          const AppSectionHeader(title: 'WHAT YOU MAY NOTICE'),
          const SizedBox(height: AppSpacing.sm2),
          Text(technique.whatYouMayNotice, style: theme.textTheme.bodyMedium),

          if (technique.tips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            const AppSectionHeader(title: 'TIPS'),
            const SizedBox(height: AppSpacing.sm2),
            AppGroupContainer(children: _bulletRows(technique.tips)),
          ],

          if (technique.warnings.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            const AppSectionHeader(title: 'GOOD TO KNOW'),
            const SizedBox(height: AppSpacing.sm2),
            AppGroupContainer(children: _bulletRows(technique.warnings)),
          ],

          if (technique.gentlerVariantId != null) ...[
            const SizedBox(height: AppSpacing.xxl),
            PremiumScaleButton(
              hapticsEnabled: hapticsEnabled,
              onTap: () {
                final variant = BreathingTechniqueCatalog.byId(
                  technique.gentlerVariantId!,
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TechniqueDetailPage(technique: variant),
                  ),
                );
              },
              child: Text(
                'Prefer a gentler pace? Try the shorter-hold version',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),
          const AppSectionHeader(title: 'DURATION'),
          const SizedBox(height: AppSpacing.sm2),
          _DurationChips(
            technique: technique,
            selected: _selectedDuration,
            onSelect: (d) => setState(() => _selectedDuration = d),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: PremiumScaleButton(
              hapticsEnabled: hapticsEnabled,
              onTap: () {
                context.read<BreathingBloc>().add(
                  ChangeTechnique(technique.id, reason: widget.reason),
                );
                context.read<BreathingBloc>().add(
                  ChangeSessionDuration(_selectedDuration),
                );
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(28),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Start',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _bulletRows(List<String> items) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) rows.add(const AppDivider());
      rows.add(
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          title: Text(items[i]),
        ),
      );
    }
    return rows;
  }
}

class _DifficultyPill extends StatelessWidget {
  final TechniqueDifficulty difficulty;
  const _DifficultyPill({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        difficulty.label,
        style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.5),
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  final List<String> items;
  const _ChipWrap({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
                ),
              ),
              child: Text(item, style: theme.textTheme.bodyMedium),
            ),
          )
          .toList(),
    );
  }
}

class _DurationChips extends StatelessWidget {
  final BreathingTechnique technique;
  final int selected;
  final ValueChanged<int> onSelect;

  const _DurationChips({
    required this.technique,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: technique.availableDurations.map((d) {
        final isSelected = d == selected;
        final isRecommended = d == technique.recommendedDuration;
        final label = [
          d == -1 ? 'Infinite' : '$d min',
          if (isRecommended) 'Recommended',
        ].join(' · ');
        return PremiumScaleButton(
          onTap: () => onSelect(d),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.14),
              ),
            ),
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
