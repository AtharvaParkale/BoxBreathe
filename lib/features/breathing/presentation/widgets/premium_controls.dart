import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PremiumScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double pressedScale;
  final bool hapticsEnabled;

  const PremiumScaleButton({
    super.key,
    required this.child,
    required this.onTap,
    this.duration = const Duration(milliseconds: 100),
    this.pressedScale = 0.95,
    this.hapticsEnabled = true,
  });

  @override
  State<PremiumScaleButton> createState() => _PremiumScaleButtonState();
}

class _PremiumScaleButtonState extends State<PremiumScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    if (widget.hapticsEnabled) HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    _controller.reverse();
    widget.onTap!();
  }

  void _onTapCancel() {
    if (widget.onTap == null) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

class PremiumIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool hapticsEnabled;
  final String? semanticLabel;

  const PremiumIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 48,
    this.hapticsEnabled = true,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onTap != null;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticLabel,
      child: PremiumScaleButton(
        onTap: onTap,
        hapticsEnabled: hapticsEnabled,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.14),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isEnabled
                ? theme.colorScheme.onSurface.withValues(alpha: 0.90)
                : theme.disabledColor,
          ),
        ),
      ),
    );
  }
}

class PremiumPlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  final bool hapticsEnabled;

  const PremiumPlayButton({
    super.key,
    required this.isPlaying,
    required this.onTap,
    this.hapticsEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: isPlaying ? 'Pause session' : 'Start session',
      child: PremiumScaleButton(
        onTap: onTap,
        pressedScale: 0.92,
        hapticsEnabled: hapticsEnabled,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 36,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
