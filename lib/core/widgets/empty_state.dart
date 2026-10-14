import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'ease_button.dart';

/// Specific, human empty state: one serif line, one sentence, optionally
/// one way forward.
class EmptyState extends StatelessWidget {
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          body,
          style: theme.bodyLarge?.copyWith(color: theme.bodyMedium?.color),
        ),
        if (actionLabel != null) ...[
          const SizedBox(height: AppSpacing.xl),
          EaseButton.primary(label: actionLabel!, onTap: onAction),
        ],
      ],
    );
  }
}
