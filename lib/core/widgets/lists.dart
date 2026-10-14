import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Small uppercase label that opens a section. Sections are separated by
/// space and type, not by boxes.
class SectionLabel extends StatelessWidget {
  final String title;
  final bool first;

  const SectionLabel(this.title, {super.key, this.first = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: first ? 0 : AppSpacing.huge,
        bottom: AppSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

/// A plain row: title, optional subtitle, optional trailing value/widget.
/// Becomes tappable (with a chevron unless [showChevron] is false) when
/// [onTap] is set. No container — rows sit on the page, separated by
/// [HairlineList] rules.
class ListRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool hapticsEnabled;
  final TextStyle? titleStyle;

  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.hapticsEnabled = true,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: titleStyle ?? theme.bodyLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: theme.bodyMedium),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: AppSpacing.lg),
              Text(
                value!,
                style: theme.bodyLarge?.copyWith(
                  color: AppColors.secondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.lg),
              trailing!,
            ] else if (onTap != null && showChevron) ...[
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.tertiary,
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return MergeSemantics(child: row);
    return Pressable(
      onTap: onTap,
      hapticsEnabled: hapticsEnabled,
      pressedScale: 1.0,
      child: row,
    );
  }
}

/// A [ListRow] with a switch. The whole row toggles.
class ToggleRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: ListRow(
          title: title,
          subtitle: subtitle,
          trailing: Switch(value: value, onChanged: onChanged),
        ),
      ),
    );
  }
}

/// Stacks rows with a hairline rule between each — the app's list style.
class HairlineList extends StatelessWidget {
  final List<Widget> children;

  const HairlineList({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(),
          children[i],
        ],
      ],
    );
  }
}
