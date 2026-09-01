import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../../core/widgets/premium_controls.dart';
import '../widgets/moment_picker.dart';
import '../bloc/breathing_bloc.dart';
import '../bloc/breathing_event.dart';
import '../bloc/breathing_state.dart';
import '../../domain/entities/breathing_mode.dart';
import '../../../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../../../features/settings/presentation/pages/settings_page.dart';
import '../../../../features/progress/presentation/pages/progress_page.dart';
import '../../../../injection_container.dart' as di;
import '../../../../core/services/sound_service.dart';

class BreathingPage extends StatefulWidget {
  const BreathingPage({super.key});

  @override
  State<BreathingPage> createState() => _BreathingPageState();
}

class _BreathingPageState extends State<BreathingPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _breathingController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Countdown State
  bool _isCountingDown = false;
  int _countdownValue = 3;

  // Haptic State Tracking
  BreathingPhase? _lastPhase;

  // Timer that returns the UI to "ready" a moment after a session completes
  Timer? _completionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Breathing Controller
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    ); // Default 16s

    _breathingController.addListener(_onBreathingTick);

    // Glow Controller (Ambient)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6), // Slower, more calming glow
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutQuad),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the OS-level reduced-motion setting: hold the ambient glow
    // steady instead of endlessly pulsing it.
    if (MediaQuery.disableAnimationsOf(context)) {
      _glowController.stop();
      _glowController.value = 0.0;
    } else if (!_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _breathingController.removeListener(_onBreathingTick);
    _breathingController.dispose();
    _glowController.dispose();
    _completionTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive) &&
        mounted &&
        context.read<BreathingBloc>().state.status ==
            BreathingStatus.active) {
      _pauseSession();
    }
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

  ({BreathingPhase phase, double scale}) _calculatePhaseAndScale(
    double t,
    BreathingMode mode,
  ) {
    int total = mode.cycleDurationMs;
    if (total == 0) {
      return (phase: BreathingPhase.inhale, scale: 0.6); // Safety
    }

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
      return (phase: BreathingPhase.inhale, scale: 0.6 + (0.4 * curve));
    } else if (t <= holdFullEnd) {
      // HOLD FULL: 1.0
      return (phase: BreathingPhase.holdFull, scale: 1.0);
    } else if (t <= exhaleEnd) {
      // EXHALE: 1.0 -> 0.6
      double localT = (t - holdFullEnd) / (mode.exhaleDurationMs / total);
      double curve = Curves.easeInOut.transform(localT);
      return (phase: BreathingPhase.exhale, scale: 1.0 - (0.4 * curve));
    } else {
      // HOLD EMPTY: 0.6
      return (phase: BreathingPhase.holdEmpty, scale: 0.6);
    }
  }

  void _selectMoment(MomentOption option) {
    if (_isCountingDown) return;
    final bloc = context.read<BreathingBloc>();
    bloc.add(ChangeBreathingMode(option.mode));
    bloc.add(ChangeSessionDuration(option.durationMinutes));
    _startSession();
  }

  void _startSession() {
    _completionTimer?.cancel();
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
        if (state.status == BreathingStatus.active) {
          WakelockPlus.enable();
        } else {
          WakelockPlus.disable();
        }

        if (state.status == BreathingStatus.completed) {
          _breathingController.stop();
          // Check settings before haptic
          if (context.read<SettingsBloc>().state.settings.isHapticEnabled) {
            HapticFeedback.heavyImpact();
          }
          final reduceMotion = MediaQuery.disableAnimationsOf(context);
          // Reset to initial visual state
          _breathingController.animateTo(
            0.0,
            duration: reduceMotion
                ? Duration.zero
                : const Duration(seconds: 2), // Slower reset
          );
          _completionTimer?.cancel();
          _completionTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) context.read<BreathingBloc>().add(StopBreathing());
          });
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
        final hapticsEnabled = context.select(
          (SettingsBloc bloc) => bloc.state.settings.isHapticEnabled,
        );

        // Calculate current visual state based on controller
        // We use AnimatedBuilder to drive the UI at 60fps
        return Scaffold(
          body: AnimatedContainer(
            duration: const Duration(seconds: 1),
            color: theme.scaffoldBackgroundColor, // Background transition
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
                          hapticsEnabled: hapticsEnabled,
                          semanticLabel: 'Choose breathing mode',
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
                                color: Colors.white.withValues(alpha: 0.50),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_formatDuration(state.mode.inhaleDurationMs)} · ${_formatDuration(state.mode.holdFullDurationMs)} · ${_formatDuration(state.mode.exhaleDurationMs)} · ${_formatDuration(state.mode.holdEmptyDurationMs)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.28),
                                letterSpacing: 1.2,
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PremiumIconButton(
                              icon: Icons.insights_rounded,
                              hapticsEnabled: hapticsEnabled,
                              semanticLabel: 'Your progress',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProgressPage(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            PremiumIconButton(
                              icon: Icons.settings_rounded,
                              hapticsEnabled: hapticsEnabled,
                              semanticLabel: 'Settings',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsPage(),
                                ),
                              ),
                            ),
                          ],
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
                        String displayLabel = phaseInfo.phase.displayLabel
                            .toUpperCase();
                        double scale = phaseInfo.scale; // 0.6 to 1.0 range

                        // Map scale (0.6 - 1.0) to Opacity — ghostly at rest, luminous when full
                        double aliveOpacity =
                            0.08 + (0.82 * ((scale - 0.6) / 0.4));

                        // Override if Countdown
                        if (_isCountingDown) {
                          scale = 0.6;
                          displayLabel = "GET READY";
                          aliveOpacity = 0.65; // keep orb visible for countdown number contrast
                        } else if (state.status == BreathingStatus.initial) {
                          scale = 0.6;
                          displayLabel = "breathe.";
                          aliveOpacity = 0.08;
                        } else if (state.status == BreathingStatus.completed) {
                          displayLabel = "you're calmer now.";
                          scale = 0.6;
                          aliveOpacity = 0.08;
                        }

                        // Soft pulsing glow
                        double ambientGlow = _glowAnimation.value * 4;

                        // Hidden before a session actually starts — at rest
                        // it just overlaps the moment-picker chips below.
                        final showTimer =
                            !_isCountingDown &&
                            state.status != BreathingStatus.initial;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(flex: 2), // Top Spacer
                            // Visual Circle
                            Semantics(
                              liveRegion: true,
                              label: _isCountingDown
                                  ? 'Get ready, starting in $_countdownValue'
                                  : '$displayLabel, ${_formatTime(state.sessionRemainingSeconds)} remaining',
                              child: ExcludeSemantics(
                                child: SizedBox(
                              width: 300,
                              height: 300,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Guide ring — fixed reference circle the orb breathes into
                                  Container(
                                    width: 260,
                                    height: 260,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        width: 1,
                                      ),
                                    ),
                                  ),

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
                                            blurRadius: 36 + ambientGlow,
                                            spreadRadius: 6 + ambientGlow,
                                          ),
                                          BoxShadow(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.07),
                                            blurRadius: 60 + ambientGlow * 2,
                                            spreadRadius: 14 + ambientGlow,
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
                                        gradient: RadialGradient(
                                          center: const Alignment(-0.3, -0.4),
                                          radius: 0.85,
                                          colors: [
                                            Color.lerp(
                                              theme.colorScheme.primary,
                                              Colors.white,
                                              0.25,
                                            )!.withValues(alpha: aliveOpacity),
                                            theme.colorScheme.primary
                                                .withValues(alpha: aliveOpacity),
                                          ],
                                        ),
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
                                textAlign: TextAlign.center,
                                key: ValueKey(displayLabel),
                                style: theme.textTheme.displayMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.55,
                                  ),
                                  fontSize:
                                      displayLabel == "you're calmer now."
                                      ? 22
                                      : null,
                                  letterSpacing:
                                      (displayLabel == "breathe." ||
                                          displayLabel ==
                                              "you're calmer now.")
                                      ? 1.5
                                      : 4.0,
                                ),
                              ),
                            ),

                            if (state.status ==
                                BreathingStatus.completed) ...[
                              const SizedBox(height: 12),
                              AnimatedOpacity(
                                opacity: 1.0,
                                duration: const Duration(milliseconds: 600),
                                child: Text(
                                  _postSessionRewardText(state),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                              ),
                            ],

                            if (showTimer) ...[
                              const SizedBox(height: 24),
                              // Timer
                              Text(
                                _formatTime(state.sessionRemainingSeconds),
                                style: theme.textTheme.headlineMedium
                                    ?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                              ),
                            ],

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
                              hapticsEnabled: hapticsEnabled,
                              semanticLabel: 'Reset session',
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
                          hapticsEnabled: hapticsEnabled,
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
                            hapticsEnabled: hapticsEnabled,
                            semanticLabel: 'Choose session duration',
                            onTap: _isCountingDown
                                ? null
                                : () => _showDurationSelector(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Moment Picker — "What do you need right now?"
                  Positioned(
                    bottom: 176,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      ignoring:
                          state.status != BreathingStatus.initial ||
                          _isCountingDown,
                      child: AnimatedOpacity(
                        opacity:
                            (state.status == BreathingStatus.initial &&
                                !_isCountingDown)
                            ? 1.0
                            : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: MomentPicker(
                          hapticsEnabled: hapticsEnabled,
                          onSelect: _selectMoment,
                        ),
                      ),
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
                                  alpha: 0.25,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Use earphones for the best experience",
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.25,
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

  String _postSessionRewardText(BreathingState state) {
    if (state.postSessionAchievementTitle != null) {
      return 'Achievement unlocked · ${state.postSessionAchievementTitle}';
    }
    final streakDays = state.postSessionStreakDays;
    if (streakDays != null) {
      return '$streakDays day${streakDays == 1 ? '' : 's'} streak';
    }
    return 'First session logged';
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
        initialChildSize: 0.38,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
