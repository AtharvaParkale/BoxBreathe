import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_containers.dart';
import '../../../../core/widgets/premium_controls.dart';
import '../../../../injection_container.dart' as di;
import '../../../progress/domain/entities/progress_session_record.dart';
import '../../../progress/domain/usecases/get_recent_sessions.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../domain/entities/breathing_technique.dart';
import '../../domain/entities/breathing_technique_catalog.dart';
import '../bloc/breathing_bloc.dart';
import '../bloc/breathing_event.dart';
import '../widgets/technique_row.dart';
import 'technique_detail_page.dart';

class TechniqueLibraryPage extends StatefulWidget {
  const TechniqueLibraryPage({super.key});

  @override
  State<TechniqueLibraryPage> createState() => _TechniqueLibraryPageState();
}

class _TechniqueLibraryPageState extends State<TechniqueLibraryPage> {
  TechniqueCategory? _expandedCategory;
  late final Future<List<ProgressSessionRecord>> _recentSessionsFuture = di
      .sl<GetRecentSessions>()(limit: 10)
      .then((result) => result.fold((_) => const <ProgressSessionRecord>[], (s) => s));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hapticsEnabled = context.select(
      (SettingsBloc bloc) => bloc.state.settings.isHapticEnabled,
    );
    final favoriteIds = context.select(
      (SettingsBloc bloc) => bloc.state.settings.favoriteTechniqueIds,
    );
    final favorites = favoriteIds
        .where(BreathingTechniqueCatalog.exists)
        .map(BreathingTechniqueCatalog.byId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Techniques'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _QuickReliefCard(
            hapticsEnabled: hapticsEnabled,
            onPicked: _startFromCategory,
          ),
          const SizedBox(height: AppSpacing.xxl),

          const AppSectionHeader(title: 'WHAT DO YOU NEED RIGHT NOW?'),
          const SizedBox(height: AppSpacing.sm2),
          _CategoryChipsRow(
            selected: _expandedCategory,
            hapticsEnabled: hapticsEnabled,
            onSelect: (category) => setState(() {
              _expandedCategory = _expandedCategory == category
                  ? null
                  : category;
            }),
          ),
          if (_expandedCategory != null) ...[
            const SizedBox(height: AppSpacing.sm2),
            AppGroupContainer(
              children: _rowsFor(
                BreathingTechniqueCatalog.featuredByCategory(
                  _expandedCategory!,
                ),
                hapticsEnabled,
                reason: _expandedCategory!.name,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),

          if (favorites.isNotEmpty) ...[
            const AppSectionHeader(title: 'FAVORITES'),
            const SizedBox(height: AppSpacing.sm2),
            AppGroupContainer(children: _rowsFor(favorites, hapticsEnabled)),
            const SizedBox(height: AppSpacing.xxl),
          ],

          FutureBuilder<List<ProgressSessionRecord>>(
            future: _recentSessionsFuture,
            builder: (context, snapshot) {
              final recent = snapshot.data ?? const [];
              final seen = <String>{};
              final distinct = <ProgressSessionRecord>[];
              for (final r in recent) {
                if (seen.add(r.techniqueId)) distinct.add(r);
                if (distinct.length == 2) break;
              }
              if (distinct.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionHeader(
                      title: 'CONTINUE WHERE YOU LEFT OFF',
                    ),
                    const SizedBox(height: AppSpacing.sm2),
                    for (final record in distinct)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.sm2,
                          bottom: 4,
                        ),
                        child: Text(
                          '${_displayNameFor(record)} · '
                          '${record.completedDurationSeconds ~/ 60} min',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          const AppSectionHeader(title: 'BROWSE ALL'),
          const SizedBox(height: AppSpacing.sm2),
          AppGroupContainer(
            children: _rowsFor(
              BreathingTechniqueCatalog.visible,
              hapticsEnabled,
            ),
          ),
        ],
      ),
    );
  }

  String _displayNameFor(ProgressSessionRecord record) {
    return BreathingTechniqueCatalog.exists(record.techniqueId)
        ? BreathingTechniqueCatalog.byId(record.techniqueId).name
        : record.techniqueName;
  }

  List<Widget> _rowsFor(
    List<BreathingTechnique> techniques,
    bool hapticsEnabled, {
    String? reason,
  }) {
    final rows = <Widget>[];
    for (var i = 0; i < techniques.length; i++) {
      if (i > 0) rows.add(const AppDivider());
      final technique = techniques[i];
      rows.add(
        TechniqueRow(
          technique: technique,
          hapticsEnabled: hapticsEnabled,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TechniqueDetailPage(technique: technique, reason: reason),
            ),
          ),
        ),
      );
    }
    return rows;
  }

  void _startFromCategory(TechniqueCategory category) {
    final technique = BreathingTechniqueCatalog.featuredByCategory(
      category,
    ).first;
    context.read<BreathingBloc>().add(
      ChangeTechnique(technique.id, reason: category.name),
    );
    context.read<BreathingBloc>().add(
      ChangeSessionDuration(technique.recommendedDuration),
    );
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}

class _QuickReliefCard extends StatelessWidget {
  final bool hapticsEnabled;
  final ValueChanged<TechniqueCategory> onPicked;

  const _QuickReliefCard({required this.hapticsEnabled, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Quick relief — not sure what you need',
      child: PremiumScaleButton(
        hapticsEnabled: hapticsEnabled,
        onTap: () => _showPicker(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Icon(Icons.bolt_rounded, color: theme.colorScheme.onPrimary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not sure what you need?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Tell us how you feel — we'll pick something",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: theme.colorScheme.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    sheetContext,
                  ).colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'How are you feeling?',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            for (final category in TechniqueCategory.values)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                title: Text(category.label),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onPicked(category);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChipsRow extends StatelessWidget {
  final TechniqueCategory? selected;
  final bool hapticsEnabled;
  final ValueChanged<TechniqueCategory> onSelect;

  const _CategoryChipsRow({
    required this.selected,
    required this.hapticsEnabled,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TechniqueCategory.values.map((category) {
        final isSelected = category == selected;
        return PremiumScaleButton(
          hapticsEnabled: hapticsEnabled,
          onTap: () => onSelect(category),
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
              '${category.emoji}  ${category.label}',
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
