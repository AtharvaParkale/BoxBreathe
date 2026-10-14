import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

/// The one tap primitive every custom control builds on: a 44pt minimum
/// hit area, a soft opacity/scale press response, optional selection
/// haptic, and button semantics.
///
/// When [semanticLabel] is given it replaces the child's own semantics
/// (useful for icon-only or multi-text controls).
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool hapticsEnabled;
  final String? semanticLabel;
  final bool? selected;
  final double minSize;
  final double pressedScale;

  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.hapticsEnabled = true,
    this.semanticLabel,
    this.selected,
    this.minSize = AppSpacing.minTarget,
    this.pressedScale = 0.98,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (widget.hapticsEnabled) HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final duration = AppMotion.of(context, AppMotion.quick);

    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? _handleTap : null,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minSize,
            minHeight: widget.minSize,
          ),
          child: AnimatedScale(
            scale: _pressed ? widget.pressedScale : 1.0,
            duration: duration,
            curve: AppMotion.standard,
            child: AnimatedOpacity(
              opacity: _pressed ? 0.55 : 1.0,
              duration: duration,
              curve: AppMotion.standard,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
