import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/premium_controls.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_event_state.dart';
import '../../domain/entities/breathing_technique.dart';

/// Shared row used across Favorites/Browse-all/category sections on the
/// technique library page.
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
    final theme = Theme.of(context);
    final isFavorite = showFavoriteToggle
        ? context.select(
            (SettingsBloc bloc) => bloc.state.settings.favoriteTechniqueIds
                .contains(technique.id),
          )
        : false;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
        child: Icon(
          technique.icon,
          size: 18,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      title: Text(technique.name),
      subtitle: Text(
        technique.shortDescription,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: !showFavoriteToggle
          ? null
          : Semantics(
              button: true,
              label: isFavorite
                  ? 'Remove from favorites'
                  : 'Add to favorites',
              child: PremiumScaleButton(
                hapticsEnabled: hapticsEnabled,
                onTap: () => context.read<SettingsBloc>().add(
                  ToggleFavoriteTechnique(technique.id),
                ),
                child: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 20,
                  color: isFavorite
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
    );
  }
}
