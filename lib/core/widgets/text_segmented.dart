import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Inline text choices with a 1px rule under the selected one — used
/// instead of pill chips for durations and filters.
class TextSegmented<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelect;
  final bool hapticsEnabled;

  /// Horizontal scroll for long option sets; otherwise options wrap.
  final bool scrollable;

  const TextSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.hapticsEnabled = true,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    final duration = AppMotion.of(context, AppMotion.base);

    final items = [
      for (final (value, label) in options)
        Pressable(
          selected: value == selected,
          hapticsEnabled: hapticsEnabled,
          onTap: () => onSelect(value),
          pressedScale: 1.0,
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: duration,
                      style: style!.copyWith(
                        color: value == selected
                            ? AppColors.white
                            : AppColors.tertiary,
                      ),
                      child: Text(label),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AnimatedContainer(
                      duration: duration,
                      curve: AppMotion.standard,
                      height: 1,
                      color: value == selected
                          ? AppColors.white
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];

    if (!scrollable) {
      return Wrap(spacing: AppSpacing.xl, children: items);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xl),
            items[i],
          ],
        ],
      ),
    );
  }
}
