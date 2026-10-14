import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ease_button.dart';
import '../bloc/breathing_bloc.dart';
import '../bloc/breathing_state.dart';
import 'home_view.dart';

/// In-session top row: just the technique name, no navigation.
class SessionHeader extends StatelessWidget {
  const SessionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.select(
      (BreathingBloc bloc) => bloc.state.technique.name,
    );
    return Center(
      child: Text(
        name.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

/// The 3-2-1 numeral shown inside the ring before a session starts.
class CountdownNumeral extends StatelessWidget {
  final int value;

  const CountdownNumeral({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.base),
      child: Text(
        '$value',
        key: ValueKey(value),
        style: Theme.of(context).textTheme.displayLarge,
      ),
    );
  }
}

/// Countdown, active and paused stage: what to do now (phase word), how
/// long it lasts, how long is left overall, and the two controls.
class SessionView extends StatelessWidget {
  final bool isCountingDown;
  final ValueListenable<int> phaseIndex;
  final ValueListenable<int> phaseSecondsLeft;
  final bool hapticsEnabled;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onCancelCountdown;

  const SessionView({
    super.key,
    required this.isCountingDown,
    required this.phaseIndex,
    required this.phaseSecondsLeft,
    required this.hapticsEnabled,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onCancelCountdown,
  });

  static const double _controlsHeight = 72 + AppSpacing.sm + 48;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final status = context.select((BreathingBloc bloc) => bloc.state.status);
    final segments = context.select(
      (BreathingBloc bloc) => bloc.state.technique.pattern.segments,
    );
    final isPaused = status == BreathingStatus.paused;
    final fade = AppMotion.of(context, AppMotion.phaseFade);

    final Widget phaseWord;
    final Widget phaseCount;
    if (isCountingDown) {
      phaseWord = Text('Get ready', style: theme.displayMedium);
      phaseCount = Text(' ', style: theme.labelMedium);
    } else {
      phaseWord = ValueListenableBuilder<int>(
        valueListenable: phaseIndex,
        builder: (context, index, _) {
          final label = isPaused
              ? 'Paused'
              : (segments.isEmpty
                    ? ''
                    : _sentenceCase(segments[index % segments.length].label));
          return Semantics(
            liveRegion: true,
            child: AnimatedSwitcher(
              duration: fade,
              switchInCurve: AppMotion.enter,
              switchOutCurve: AppMotion.exit,
              child: Text(
                label,
                key: ValueKey(label),
                style: theme.displayMedium,
              ),
            ),
          );
        },
      );
      phaseCount = ExcludeSemantics(
        child: ValueListenableBuilder<int>(
          valueListenable: phaseSecondsLeft,
          builder: (context, seconds, _) => AnimatedOpacity(
            opacity: isPaused ? 0 : 1,
            duration: AppMotion.of(context, AppMotion.base),
            child: Text(
              '$seconds',
              style: theme.labelMedium?.copyWith(color: AppColors.tertiary),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        phaseWord,
        const SizedBox(height: AppSpacing.xs),
        phaseCount,
        const SizedBox(height: AppSpacing.lg),
        isCountingDown ? const _SessionSummary() : const _SessionClock(),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          height: _controlsHeight,
          child: isCountingDown
              ? Center(
                  child: EaseButton.quiet(
                    label: 'Cancel',
                    semanticLabel: 'Cancel countdown',
                    hapticsEnabled: hapticsEnabled,
                    onTap: onCancelCountdown,
                  ),
                )
              : Column(
                  children: [
                    RoundControl(
                      icon: isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      semanticLabel: isPaused
                          ? 'Resume session'
                          : 'Pause session',
                      hapticsEnabled: hapticsEnabled,
                      onTap: isPaused ? onResume : onPause,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    EaseButton.quiet(
                      label: 'Stop',
                      semanticLabel: 'Stop session',
                      hapticsEnabled: hapticsEnabled,
                      onTap: onStop,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  static String _sentenceCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

/// "Box breathing · 4 min" — what's about to start, shown during countdown.
class _SessionSummary extends StatelessWidget {
  const _SessionSummary();

  @override
  Widget build(BuildContext context) {
    final state = context.read<BreathingBloc>().state;
    return Text(
      '${state.technique.name} · ${formatDurationChoice(state.sessionDurationMinutes)}',
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}

/// Remaining time (or elapsed, for open-ended sessions). Only this text
/// rebuilds on each one-second tick.
class _SessionClock extends StatelessWidget {
  const _SessionClock();

  @override
  Widget build(BuildContext context) {
    final (remaining, elapsedMs) = context.select(
      (BreathingBloc bloc) =>
          (bloc.state.sessionRemainingSeconds, bloc.state.sessionElapsedMs),
    );
    final openEnded = remaining < 0;
    final seconds = openEnded ? elapsedMs ~/ 1000 : remaining;
    final text = '${formatClock(seconds)} ${openEnded ? 'elapsed' : 'left'}';
    return Semantics(
      label: openEnded
          ? '${formatClock(seconds)} elapsed'
          : '${formatClock(seconds)} remaining',
      child: ExcludeSemantics(
        child: Text(text, style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}

/// m:ss
String formatClock(int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}
