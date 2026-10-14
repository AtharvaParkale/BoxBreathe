import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/breathing_pattern.dart';

/// How the orb should read the breathing cycle.
enum OrbMode {
  /// Small, dim, still — home and countdown.
  rest,

  /// Follows the cycle, with the per-phase progress arc and a faint halo.
  breathing,

  /// Follows the cycle (frozen while the controller is stopped), arc kept,
  /// no halo — reads as "held".
  paused,

  /// Follows the cycle with no arc or halo — the post-session settle back
  /// to rest, and the onboarding demo.
  follow,
}

/// The breathing orb: a fixed hairline guide ring and a solid white disc
/// that grows into it on the inhale and recedes on the exhale.
///
/// Painted directly from [cycle] (`CustomPainter(repaint:)`), so the 60fps
/// animation repaints only this layer — nothing above it rebuilds.
class BreathingOrb extends StatelessWidget {
  final Animation<double> cycle;
  final BreathingPattern pattern;
  final OrbMode mode;
  final double size;

  /// Optional content centred inside the ring (e.g. countdown numeral).
  final Widget? center;

  const BreathingOrb({
    super.key,
    required this.cycle,
    required this.pattern,
    required this.mode,
    required this.size,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              size: Size.square(size),
              painter: _OrbPainter(cycle: cycle, pattern: pattern, mode: mode),
            ),
          ),
          ?center,
        ],
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final Animation<double> cycle;
  final BreathingPattern pattern;
  final OrbMode mode;

  _OrbPainter({required this.cycle, required this.pattern, required this.mode})
    : super(repaint: cycle);

  static const double _restScale = 0.6;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final ringRadius = size.shortestSide / 2 - 1;
    final maxDisc = ringRadius * 0.9;

    final t = cycle.value;
    final double scale = mode == OrbMode.rest
        ? _restScale
        : pattern.phaseAt(t).scale;
    // 0 at rest size, 1 at full breath.
    final fullness = ((scale - _restScale) / (1 - _restScale)).clamp(0.0, 1.0);
    final discRadius = maxDisc * scale;

    // Guide ring — the fixed space the breath fills.
    canvas.drawCircle(
      c,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.hairline,
    );

    // Single faint halo while actively breathing; scales with the breath,
    // never pulses on its own.
    if (mode == OrbMode.breathing) {
      canvas.drawCircle(
        c,
        discRadius * 1.06,
        Paint()
          ..color = AppColors.white.withValues(alpha: 0.07 * fullness)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
    }

    // The disc.
    final alpha = mode == OrbMode.rest ? 0.12 : 0.16 + 0.76 * fullness;
    canvas.drawCircle(
      c,
      discRadius,
      Paint()..color = AppColors.white.withValues(alpha: alpha),
    );

    // Progress through the current phase, traced along the guide ring.
    if (mode == OrbMode.breathing || mode == OrbMode.paused) {
      final progress = pattern.segmentAt(t).progress;
      if (progress > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: ringRadius),
          -math.pi / 2,
          2 * math.pi * progress,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round
            ..color = AppColors.secondary,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.mode != mode || old.pattern != pattern || old.cycle != cycle;
}
