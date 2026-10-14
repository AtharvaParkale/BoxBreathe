import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ease_button.dart';
import '../../../../core/widgets/ease_page.dart';
import '../../../../core/widgets/lists.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/text_segmented.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_event_state.dart';
import '../../domain/entities/breathing_technique.dart';
import '../../domain/entities/breathing_technique_catalog.dart';
import '../bloc/breathing_bloc.dart';
import '../bloc/breathing_event.dart';
import '../widgets/home_view.dart';
import '../widgets/rhythm_bar.dart';

/// Everything about one technique, read top-down: what it is, its rhythm,
/// how to do it, when it helps, what to watch for — then Begin.
///
/// Pops with `true` when the user taps Begin, so callers can start the
/// session immediately.
class TechniqueDetailPage extends StatefulWidget {
  final BreathingTechnique technique;

  /// Carried through if the user arrived via a need-based entry point
  /// (e.g. a "What do you need right now?" category), for session
  /// analytics — not shown in the UI.
  final String? reason;

  const TechniqueDetailPage({super.key, required this.technique, this.reason});

  @override
  State<TechniqueDetailPage> createState() => _TechniqueDetailPageState();
}

class _TechniqueDetailPageState extends State<TechniqueDetailPage> {
  late int _selectedDuration = widget.technique.recommendedDuration;

  void _begin() {
    final bloc = context.read<BreathingBloc>();
    bloc.add(ChangeTechnique(widget.technique.id, reason: widget.reason));
    bloc.add(ChangeSessionDuration(_selectedDuration));
    Navigator.pop(context, true);
  }

  Future<void> _openGentlerVariant() async {
    final variant = BreathingTechniqueCatalog.byId(
      widget.technique.gentlerVariantId!,
    );
    final start = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TechniqueDetailPage(technique: variant, reason: widget.reason),
      ),
    );
    if (start == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final technique = widget.technique;
    final hapticsEnabled = context.select(
      (SettingsBloc bloc) => bloc.state.settings.isHapticEnabled,
    );
    final isFavorite = context.select(
      (SettingsBloc bloc) =>
          bloc.state.settings.favoriteTechniqueIds.contains(technique.id),
    );

    return EasePage(
      title: technique.name,
      actions: [
        Pressable(
          hapticsEnabled: hapticsEnabled,
          selected: isFavorite,
          semanticLabel: isFavorite
              ? 'Remove from favorites'
              : 'Add to favorites',
          onTap: () => context.read<SettingsBloc>().add(
            ToggleFavoriteTechnique(technique.id),
          ),
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 22,
            color: isFavorite ? AppColors.white : AppColors.secondary,
          ),
        ),
      ],
      bottomBar: BottomActionBar(
        child: EaseButton.primary(
          label: 'Begin · ${formatDurationChoice(_selectedDuration)}',
          semanticLabel:
              'Begin ${technique.name}, ${formatDurationChoice(_selectedDuration)}',
          hapticsEnabled: hapticsEnabled,
          onTap: _begin,
        ),
      ),
      slivers: [
        GutterSliver(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${technique.difficulty.label} · '
                '${formatDurationChoice(technique.recommendedDuration)} suggested',
                style: theme.bodyMedium?.copyWith(color: AppColors.tertiary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(technique.shortDescription, style: theme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              Text(
                technique.longDescription,
                style: theme.bodyLarge?.copyWith(color: AppColors.secondary),
              ),

              const SectionLabel('Rhythm'),
              const SizedBox(height: AppSpacing.sm),
              RhythmBar(pattern: technique.pattern),

              if (technique.instructions.isNotEmpty) ...[
                const SectionLabel('How to'),
                _NumberedList(items: technique.instructions),
              ],

              if (technique.benefits.isNotEmpty) ...[
                const SectionLabel('Helps with'),
                Text(_sentenceList(technique.benefits), style: theme.bodyLarge),
              ],

              if (technique.useCases.isNotEmpty) ...[
                const SectionLabel('When to use it'),
                HairlineList(
                  children: [
                    for (final u in technique.useCases) ListRow(title: u),
                  ],
                ),
              ],

              const SectionLabel('What you may notice'),
              Text(
                technique.whatYouMayNotice,
                style: theme.bodyLarge?.copyWith(color: AppColors.secondary),
              ),

              if (technique.tips.isNotEmpty) ...[
                const SectionLabel('Tips'),
                HairlineList(
                  children: [for (final t in technique.tips) ListRow(title: t)],
                ),
              ],

              if (technique.warnings.isNotEmpty) ...[
                const SectionLabel('Good to know'),
                _RuledNote(items: technique.warnings),
              ],

              if (technique.gentlerVariantId != null) ...[
                const SizedBox(height: AppSpacing.xl),
                Pressable(
                  hapticsEnabled: hapticsEnabled,
                  onTap: _openGentlerVariant,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Prefer a gentler pace? Try the shorter-hold version',
                      style: theme.bodyLarge?.copyWith(
                        color: AppColors.secondary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.disabled,
                      ),
                    ),
                  ),
                ),
              ],

              const SectionLabel('Duration'),
              TextSegmented<int>(
                hapticsEnabled: hapticsEnabled,
                selected: _selectedDuration,
                onSelect: (d) => setState(() => _selectedDuration = d),
                options: [
                  for (final d in technique.availableDurations)
                    (d, formatDurationChoice(d)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// "Stress, focus and sleep." from ["Stress", "Focus", "Sleep"].
  static String _sentenceList(List<String> items) {
    if (items.length == 1) return '${items.first}.';
    final lower = [
      items.first,
      ...items
          .skip(1)
          .map((s) => s.isEmpty ? s : s[0].toLowerCase() + s.substring(1)),
    ];
    return '${lower.sublist(0, lower.length - 1).join(', ')} and ${lower.last}.';
  }
}

class _NumberedList extends StatelessWidget {
  final List<String> items;

  const _NumberedList({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${i + 1}',
                    style: theme.headlineSmall?.copyWith(
                      color: AppColors.tertiary,
                    ),
                  ),
                ),
                Expanded(child: Text(items[i], style: theme.bodyLarge)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Safety notes, set apart by a single left rule rather than colour.
class _RuledNote extends StatelessWidget {
  final List<String> items;

  const _RuledNote({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.white)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            Text(items[i], style: theme.bodyLarge),
          ],
        ],
      ),
    );
  }
}
