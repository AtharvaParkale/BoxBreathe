import 'package:flutter/material.dart';

import '../../domain/entities/breathing_pattern.dart';

/// Renders a pattern's segments as a static "Inhale · 4s -> Hold · 4s -> ..."
/// row — generic over segment count, so the same code handles Box's 4
/// segments and Physiological Sigh's 3.
class PhaseBreakdownRow extends StatelessWidget {
  final BreathingPattern pattern;

  const PhaseBreakdownRow({super.key, required this.pattern});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < pattern.segments.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
              ),
            ),
          _SegmentChip(segment: pattern.segments[i]),
        ],
      ],
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final PhaseSegment segment;
  const _SegmentChip({required this.segment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seconds = segment.durationMs / 1000;
    final secondsLabel = seconds == seconds.toInt()
        ? '${seconds.toInt()}s'
        : '${seconds}s';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            segment.label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(secondsLabel, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
