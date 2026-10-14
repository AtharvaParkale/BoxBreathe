import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_event_state.dart';
import '../../domain/entities/breathing_pattern.dart';
import '../../domain/entities/breathing_technique.dart';

/// "4 · 7 · 8" — a technique's rhythm at a glance.
String patternSignature(BreathingPattern pattern) =>
    pattern.segments.map((s) => formatPhaseSeconds(s.durationMs)).join(' · ');

/// One technique in a list: name with its rhythm, a one-line description,
/// and a favorite toggle.
class TechniqueRow extends StatelessWidget {
  final BreathingTechnique technique;
  final VoidCallback onTap;
  final bool hapticsEnabled;
  final bool showFavoriteToggle;

  const TechniqueRow({
    super.key,
    required this.technique,
    required this.onTap,
    this.hapticsEnabled = true,
    this.showFavoriteToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final isFavorite =
        showFavoriteToggle &&
        context.select(
          (SettingsBloc bloc) =>
              bloc.state.settings.favoriteTechniqueIds.contains(technique.id),
        );

    return Pressable(
      onTap: onTap,
      hapticsEnabled: hapticsEnabled,
      pressedScale: 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.md,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      Text(technique.name, style: theme.titleMedium),
                      Semantics(
                        label: 'Rhythm ${patternSignature(technique.pattern)}',
                        child: ExcludeSemantics(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              patternSignature(technique.pattern),
                              style: theme.bodySmall?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    technique.shortDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (showFavoriteToggle)
              Pressable(
                hapticsEnabled: hapticsEnabled,
                selected: isFavorite,
                semanticLabel: isFavorite
                    ? 'Remove ${technique.name} from favorites'
                    : 'Add ${technique.name} to favorites',
                onTap: () => context.read<SettingsBloc>().add(
                  ToggleFavoriteTechnique(technique.id),
                ),
                child: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 20,
                  color: isFavorite ? AppColors.white : AppColors.disabled,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
