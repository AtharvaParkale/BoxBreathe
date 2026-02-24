import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/premium_controls.dart';
import '../bloc/breathing_bloc.dart';
import '../bloc/breathing_event.dart';
import '../bloc/breathing_state.dart';
import '../../domain/entities/breathing_mode.dart';
import '../../../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../../../features/settings/presentation/pages/settings_page.dart';
import '../../../../injection_container.dart' as di;
import '../../../../core/services/sound_service.dart';

class BreathingPage extends StatefulWidget {
  const BreathingPage({super.key});

  @override
  State<BreathingPage> createState() => _BreathingPageState();
}

class _BreathingPageState extends State<BreathingPage>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Countdown State
  bool _isCountingDown = false;
  int _countdownValue = 3;
  AnimationController? _countdownController;

  // Haptic State Tracking
  String _lastPhase = '';

  @override
  void initState() {
    super.initState();
    // Breathing Controller
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    ); // Default 16s

    _breathingController.addListener(_onBreathingTick);

    // Glow Controller (Ambient)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Slower, more calming glow
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutQuad),
    );
  }

  @override
  void dispose() {
    _breathingController.removeListener(_onBreathingTick);
    _breathingController.dispose();
    _glowController.dispose();
    _countdownController?.dispose();
    super.dispose();
  }

  void _onBreathingTick() {
    final state = context.read<BreathingBloc>().state;
    final phaseInfo = _calculatePhaseAndScale(
      _breathingController.value,
      state.mode,
    );

    // Haptics & Sound Trigger
    if (phaseInfo.phase != _lastPhase) {
      final settings = context.read<SettingsBloc>().state.settings;

      // Sound Cues
      if (settings.isSoundEnabled) {
        di.sl<SoundService>().playPhaseSound(settings.soundCue);
      }

      // Haptics
      if (settings.isHapticEnabled) {
        // Trigger haptic at EVERY phase start (Inhale, Hold, Exhale)
        _triggerPhaseHaptic();
      }
      _lastPhase = phaseInfo.phase;
    }
  }

  void _triggerPhaseHaptic() {
    // Double Pulse Haptic
    HapticFeedback.lightImpact(); // Softened for premium feel
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) HapticFeedback.lightImpact();
    });
  }

  ({String phase, double scale}) _calculatePhaseAndScale(
    double t,
    BreathingMode mode,
  ) {
    int total = mode.cycleDurationMs;
    if (total == 0) return (phase: 'Inhale', scale: 0.6); // Safety

    // Normalize durations to 0.0 - 1.0 range
    double inhaleEnd = mode.inhaleDurationMs / total;
    double holdFullEnd = inhaleEnd + (mode.holdFullDurationMs / total);
    double exhaleEnd = holdFullEnd + (mode.exhaleDurationMs / total);

    // Identify Phase and calculate Scale
    if (t <= inhaleEnd) {
      // INHALE: 0.6 -> 1.0
      double localT = t / inhaleEnd;
      // Use efficient sine-like curve: easeInOutCubicEmphasized is good but custom sine is smoother for breathing
      double curve = Curves.easeInOut.transform(localT);
      return (phase: 'Inhale', scale: 0.6 + (0.4 * curve));
    } else if (t <= holdFullEnd) {
      // HOLD FULL: 1.0
      return (phase: 'Hold', scale: 1.0);
    } else if (t <= exhaleEnd) {
      // EXHALE: 1.0 -> 0.6
      double localT = (t - holdFullEnd) / (mode.exhaleDurationMs / total);
      double curve = Curves.easeInOut.transform(localT);
      return (phase: 'Exhale', scale: 1.0 - (0.4 * curve));
    } else {
      // HOLD EMPTY: 0.6
      return (phase: 'Hold', scale: 0.6);
    }
  }

  void _startSession() {
    // Check if we need countdown
    setState(() {
      _isCountingDown = true;
      _countdownValue = 3;
    });

    _runCountdown();
  }

  void _runCountdown() async {
    final settings = context.read<SettingsBloc>().state.settings;
    for (int i = 3; i > 0; i--) {
      if (!mounted) return;
      setState(() => _countdownValue = i);

      // Play Sound if enabled
      if (settings.isSoundEnabled) {
        di.sl<SoundService>().playPhaseSound(settings.soundCue);
      }

      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;

    setState(() {
      _isCountingDown = false;
    });

    // Start Breathing Animation & BLoC Timer
    final mode = context.read<BreathingBloc>().state.mode;
    _breathingController.duration = Duration(
      milliseconds: mode.cycleDurationMs,
    );
    _breathingController.repeat();
    context.read<BreathingBloc>().add(StartBreathing());
  }

  void _pauseSession() {
    _breathingController.stop();
    context.read<BreathingBloc>().add(PauseBreathing());
  }

  void _resumeSession() {
    // Smoothly resume from current position to end, then loop
    _breathingController.forward(from: _breathingController.value).whenComplete(
      () {
        if (context.read<BreathingBloc>().state.status ==
            BreathingStatus.active) {
          _breathingController.repeat();
        }
      },
    );

    context.read<BreathingBloc>().add(ResumeBreathing());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BreathingBloc, BreathingState>(
      listenWhen: (previous, current) =>
          previous.status != current.status || previous.mode != current.mode,
      listener: (context, state) {
        if (state.status == BreathingStatus.completed) {
          _breathingController.stop();
          // Check settings before haptic
          if (context.read<SettingsBloc>().state.settings.isHapticEnabled) {
            HapticFeedback.heavyImpact();
          }
          // Reset to initial visual state
          _breathingController.animateTo(
            0.0,
            duration: const Duration(seconds: 2),
          ); // Slower reset
        } else if (state.status == BreathingStatus.initial) {
          _breathingController.reset();
          _breathingController.value = 0.0; // Ensure start small
        } else if (state.mode.cycleDurationMs !=
            _breathingController.duration?.inMilliseconds) {
          // Mode changed
          _breathingController.duration = Duration(
            milliseconds: state.mode.cycleDurationMs,
          );
        }
      },
      builder: (context, state) {
        final theme = Theme.of(context);

        // Calculate current visual state based on controller
        // We use AnimatedBuilder to drive the UI at 60fps
        return Scaffold(
          body: AnimatedContainer(
            duration: const Duration(seconds: 1),
            color: theme.colorScheme.surface, // Background transition
            child: SafeArea(
              child: Stack(
                children: [
                  // Top Bar (Custom)
                  Positioned(
                    top: 16,
                    left: 24,
                    right: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PremiumIconButton(
                          icon: Icons.grid_view_rounded,
                          onTap: _isCountingDown
                              ? null
                              : () => _showModeSelector(context),
                        ),
                        // Mode Label (Center)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.mode.name.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.05,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_formatDuration(state.mode.inhaleDurationMs)} • ${_formatDuration(state.mode.holdFullDurationMs)} • ${_formatDuration(state.mode.exhaleDurationMs)} • ${_formatDuration(state.mode.holdEmptyDurationMs)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                  letterSpacing: 1.2,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        PremiumIconButton(
                          icon: Icons.settings_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsPage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main Breathing Content (Centered)
                  Center(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _breathingController,
                        _glowAnimation,
                      ]),
                      builder: (context, child) {
                        // Determine Phase & Scale
                        final phaseInfo = _calculatePhaseAndScale(
                          _breathingController.value,
                          state.mode,
                        );
                        String displayLabel = phaseInfo.phase.toUpperCase();
                        double scale = phaseInfo.scale; // 0.6 to 1.0 range

                        // Map scale (0.6 - 1.0) to Opacity (0.8 - 1.0) for "Alive" feel
                        // (scale - 0.6) / 0.4 gives 0.0 - 1.0
                        double aliveOpacity =
                            0.7 + (0.3 * ((scale - 0.6) / 0.4));

                        // Override if Countdown
                        if (_isCountingDown) {
                          scale = 0.6;
                          displayLabel = "GET READY";
                          aliveOpacity = 0.7;
                        } else if (state.status == BreathingStatus.initial) {
                          scale = 0.6;
                          displayLabel = "READY";
                          aliveOpacity = 0.7;
                        } else if (state.status == BreathingStatus.completed) {
                          displayLabel = "DONE";
                          scale = 0.6;
                        }

                        // Soft pulsing glow
                        double ambientGlow = _glowAnimation.value * 5;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(flex: 2), // Top Spacer
                            // Visual Circle
                            SizedBox(
                              width: 300,
                              height: 300,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer Soft Glow (Breathing)
                                  Transform.scale(
                                    scale: scale * 1.05, // Slightly larger
                                    child: Container(
                                      width: 220,
                                      height: 220,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.15),
                                            blurRadius: 40 + ambientGlow,
                                            spreadRadius: 10 + ambientGlow,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Main Breathing Object
                                  Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width: 220,
                                      height: 220,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withValues(
                                              alpha: aliveOpacity,
                                            ), // Dynamic Opacity
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          // Inner depth/glow
                                          BoxShadow(
                                            color: theme.colorScheme.surface
                                                .withValues(alpha: 0.2),
                                            blurRadius: 20,
                                            spreadRadius: -10,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Countdown Overlay
                                  if (_isCountingDown)
                                    Text(
                                      "$_countdownValue",
                                      style: theme.textTheme.displayLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.surface,
                                            fontWeight: FontWeight.w300,
                                          ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 48),

                            // Phase Text
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                              child: Text(
                                displayLabel,
                                key: ValueKey(displayLabel),
                                style: theme.textTheme.displayMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                  letterSpacing: 4.0, // Airy phase text
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Timer
                            Text(
                              _formatTime(state.sessionRemainingSeconds),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),

                            const Spacer(flex: 3), // Bottom Spacer
                          ],
                        );
                      },
                    ),
                  ),

                  // Bottom Controls (Play/Pause)
                  Positioned(
                    bottom: 48,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Reset Session Button
                        AnimatedOpacity(
                          opacity:
                              (state.status == BreathingStatus.active ||
                                  state.status == BreathingStatus.paused)
                              ? 1.0
                              : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 32),
                            child: PremiumIconButton(
                              icon: Icons.refresh_rounded,
                              size: 56,
                              onTap: () {
                                context.read<BreathingBloc>().add(
                                  StopBreathing(),
                                );
                              },
                            ),
                          ),
                        ),

                        // Main Play Button
                        PremiumPlayButton(
                          isPlaying: state.status == BreathingStatus.active,
                          onTap: () {
                            if (_isCountingDown) return;
                            if (state.status == BreathingStatus.active) {
                              _pauseSession();
                            } else if (state.status == BreathingStatus.paused) {
                              _resumeSession();
                            } else {
                              _startSession();
                            }
                          },
                        ),

                        // Duration Selector (Right side balance)
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: PremiumIconButton(
                            icon: Icons.timer_outlined,
                            size: 56,
                            onTap: _isCountingDown
                                ? null
                                : () => _showDurationSelector(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Earphone Suggestion (Bottom Center)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Builder(
                      builder: (context) {
                        final isSoundEnabled = context.select(
                          (SettingsBloc bloc) =>
                              bloc.state.settings.isSoundEnabled,
                        );
                        return AnimatedOpacity(
                          opacity:
                              (isSoundEnabled &&
                                  state.status == BreathingStatus.initial &&
                                  !_isCountingDown)
                              ? 1.0
                              : 0.0,
                          duration: const Duration(milliseconds: 800),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.headphones_outlined,
                                size: 12,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Use earphones for the best experience",
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.3,
                                  ),
                                  fontWeight: FontWeight.w400,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds == -1) return '∞';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int ms) {
    final double seconds = ms / 1000;
    return seconds == seconds.toInt() ? '${seconds.toInt()}s' : '${seconds}s';
  }

  void _showModeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Breathing Mode",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 48),
                    children: [
                      ...BreathingMode.values.map(
                        (mode) => ListTile(
                          title: Text(mode.name),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          onTap: () {
                            context.read<BreathingBloc>().add(
                              ChangeBreathingMode(mode),
                            );
                            _breathingController.duration = Duration(
                              milliseconds: mode.cycleDurationMs,
                            );
                            Navigator.pop(context);
                          },
                          trailing:
                              context.read<BreathingBloc>().state.mode == mode
                              ? Icon(
                                  Icons.circle,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 12,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDurationSelector(BuildContext context) {
    final durations = [1, 3, 5, 10, -1];
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Duration", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            ...durations.map(
              (d) => ListTile(
                title: Text(d == -1 ? 'Infinite' : '$d min'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                onTap: () {
                  context.read<BreathingBloc>().add(ChangeSessionDuration(d));
                  Navigator.pop(context);
                },
                trailing:
                    context
                            .read<BreathingBloc>()
                            .state
                            .sessionDurationMinutes ==
                        d
                    ? Icon(
                        Icons.circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 12,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
