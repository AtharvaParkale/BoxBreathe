import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

enum _EaseButtonKind { primary, quiet }

/// Text buttons. [EaseButton.primary] is the single solid-white call to
/// action a screen gets; [EaseButton.quiet] is everything secondary.
class EaseButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool hapticsEnabled;
  final String? semanticLabel;
  final _EaseButtonKind _kind;

  const EaseButton.primary({
    super.key,
    required this.label,
    required this.onTap,
    this.hapticsEnabled = true,
    this.semanticLabel,
  }) : _kind = _EaseButtonKind.primary;

  const EaseButton.quiet({
    super.key,
    required this.label,
    required this.onTap,
    this.hapticsEnabled = true,
    this.semanticLabel,
  }) : _kind = _EaseButtonKind.quiet;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    final enabled = onTap != null;
    final isPrimary = _kind == _EaseButtonKind.primary;

    final Widget body = isPrimary
        ? Container(
            height: 56,
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            decoration: BoxDecoration(
              color: enabled ? AppColors.white : AppColors.disabled,
              borderRadius: BorderRadius.circular(AppRadius.soft),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style?.copyWith(color: AppColors.black),
            ),
          )
        : Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style?.copyWith(
                  color: enabled ? AppColors.secondary : AppColors.disabled,
                ),
              ),
            ),
          );

    return Pressable(
      onTap: onTap,
      hapticsEnabled: hapticsEnabled,
      semanticLabel: semanticLabel,
      child: body,
    );
  }
}

/// Circular outline control for in-session actions (pause/resume). The
/// only round button style in the app.
class RoundControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final double size;
  final bool hapticsEnabled;

  const RoundControl({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.size = 72,
    this.hapticsEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      hapticsEnabled: hapticsEnabled,
      semanticLabel: semanticLabel,
      pressedScale: 0.94,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.disabled),
        ),
        child: Icon(icon, size: size * 0.36, color: AppColors.white),
      ),
    );
  }
}
