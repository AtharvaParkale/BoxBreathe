import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Rounded, bordered card used to group related list tiles/switches —
/// the settings page's visual "section" primitive.
class AppGroupContainer extends StatelessWidget {
  final List<Widget> children;

  const AppGroupContainer({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }
}

/// Hairline divider between rows inside an [AppGroupContainer].
class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

/// Small uppercase label above an [AppGroupContainer] (e.g. "PREFERENCES").
class AppSectionHeader extends StatelessWidget {
  final String title;

  const AppSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm2),
      child: Text(title, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
