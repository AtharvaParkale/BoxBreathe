import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/breathing_bloc.dart';
import '../bloc/breathing_event.dart';
import '../bloc/breathing_state.dart';
import '../../domain/entities/breathing_mode.dart';
import '../../../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../../../features/settings/presentation/pages/settings_page.dart';

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
        vsync: this, duration: const Duration(seconds: 16)); // Default 16s

    _breathingController.addListener(_onBreathingTick);

    // Glow Controller (Ambient)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOutQuad));
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
    final phaseInfo = _calculatePhaseAndScale(_breathingController.value, state.mode);
    
    // Haptics Trigger
    if (phaseInfo.phase != _lastPhase) {
      final isHapticEnabled = context.read<SettingsBloc>().state.settings.isHapticEnabled;
      if (isHapticEnabled) {
        if (phaseInfo.phase == 'Inhale') {
          HapticFeedback.selectionClick();
        } else if (phaseInfo.phase == 'Exhale') {
          HapticFeedback.selectionClick();
        }
      }
      _lastPhase = phaseInfo.phase;
    }
  }

  ({String phase, double scale}) _calculatePhaseAndScale(double t, BreathingMode mode) {
    int total = mode.cycleDuration;
    if (total == 0) return (phase: 'Inhale', scale: 0.6); // Safety

    // Normalize durations to 0.0 - 1.0 range
    double inhaleEnd = mode.inhaleDuration / total;
    double holdFullEnd = inhaleEnd + (mode.holdFullDuration / total);
    double exhaleEnd = holdFullEnd + (mode.exhaleDuration / total);
    
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
      double localT = (t - holdFullEnd) / (mode.exhaleDuration / total);
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
    for (int i = 3; i > 0; i--) {
      if (!mounted) return;
      setState(() => _countdownValue = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    
    if (!mounted) return;
    
    setState(() {
      _isCountingDown = false;
    });

    // Start Breathing Animation & BLoC Timer
    final mode = context.read<BreathingBloc>().state.mode;
    _breathingController.duration = Duration(seconds: mode.cycleDuration);
    _breathingController.repeat();
    context.read<BreathingBloc>().add(StartBreathing());
  }

  void _pauseSession() {
    _breathingController.stop();
    context.read<BreathingBloc>().add(PauseBreathing());
  }

  void _resumeSession() {
    // Smoothly resume from current position to end, then loop
    _breathingController.forward(from: _breathingController.value).whenComplete(() {
      if (context.read<BreathingBloc>().state.status == BreathingStatus.active) {
        _breathingController.repeat();
      }
    });
    
    context.read<BreathingBloc>().add(ResumeBreathing());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BreathingBloc, BreathingState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.mode != current.mode,
      listener: (context, state) {
        if (state.status == BreathingStatus.completed) {
          _breathingController.stop();
          // Check settings before haptic
          if (context.read<SettingsBloc>().state.settings.isHapticEnabled) {
            HapticFeedback.mediumImpact();
          }
          // Reset to initial visual state
           _breathingController.animateTo(0.0, duration: const Duration(seconds: 1));
        } else if (state.status == BreathingStatus.initial) {
             _breathingController.reset();
             _breathingController.value = 0.0; // Ensure start small
        } else if (state.mode.cycleDuration != _breathingController.duration?.inSeconds) {
             // Mode changed
             _breathingController.duration = Duration(seconds: state.mode.cycleDuration);
        }
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        
        // Calculate current visual state based on controller
        // We use AnimatedBuilder to drive the UI at 60fps
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Top Bar
               Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMinimalButton(
                        context, 
                        icon: Icons.grid_view_rounded, 
                        onTap: () => _isCountingDown || state.status == BreathingStatus.active ? null : _showModeSelector(context),
                      ),
                      _buildMinimalButton(
                        context, 
                        icon: Icons.timer_rounded, 
                        onTap: () => _isCountingDown || state.status == BreathingStatus.active ? null : _showDurationSelector(context),
                      ),
                      _buildMinimalButton(
                        context, 
                        icon: Icons.settings_rounded, 
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsPage()),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Centered Breathing Content
                Expanded(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_breathingController, _glowAnimation]),
                    builder: (context, child) {
                      // Determine Phase & Scale
                      final phaseInfo = _calculatePhaseAndScale(_breathingController.value, state.mode);
                      String displayLabel = phaseInfo.phase.toUpperCase();
                      double scale = phaseInfo.scale;
                      
                      // Override if Countdown
                      if (_isCountingDown) {
                        scale = 0.6;
                        displayLabel = "GET READY";
                      } else if (state.status == BreathingStatus.initial) {
                        scale = 0.6;
                        displayLabel = "READY";
                      } else if (state.status == BreathingStatus.completed) {
                        displayLabel = "DONE";
                      }

                      return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Circle
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Glow dropshadows
                                Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    width: 220,
                                    height: 220,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                          blurRadius: 30 + _glowAnimation.value,
                                          spreadRadius: _glowAnimation.value,
                                        ),
                                        BoxShadow(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                          blurRadius: 60,
                                          spreadRadius: 10 + _glowAnimation.value,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Main Circle
                                Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    width: 220,
                                    height: 220,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.9),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                // Countdown Overlay
                                if (_isCountingDown)
                                  Text(
                                    "$_countdownValue",
                                    style: theme.textTheme.displayLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 80),
                            
                            // Phase Text
                             AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    displayLabel,
                                    key: ValueKey(displayLabel),
                                    style: theme.textTheme.displayMedium,
                                  ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Timer
                             Text(
                              _formatTime(state.sessionRemainingSeconds),
                              style: theme.textTheme.headlineMedium,
                            ),
                          ],
                      );
                    },
                  ),
                ),
                
                 // Bottom Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: GestureDetector(
                    onTap: () {
                      if (_isCountingDown) return; // Disable interactions during countdown
                      
                      if (state.status == BreathingStatus.active) {
                        _pauseSession();
                      } else if (state.status == BreathingStatus.paused) {
                         _resumeSession();
                      } else {
                         // Start new session
                         _startSession();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        state.status == BreathingStatus.active
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 32,
                        color: theme.colorScheme.onSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinimalButton(BuildContext context, {required IconData icon, required VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
           color: theme.colorScheme.secondary.withValues(alpha: 0.5),
           shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: onTap == null ? theme.disabledColor : theme.colorScheme.onSurface.withValues(alpha: 0.8)),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds == -1) return '∞';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showModeSelector(BuildContext context) {
      showModalBottomSheet(
          context: context, 
          builder: (_) => Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Select Mode", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 24),
                    ...BreathingMode.values.map((mode) => ListTile(
                      title: Text(mode.name),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      onTap: () {
                          context.read<BreathingBloc>().add(ChangeBreathingMode(mode));
                          _breathingController.duration = Duration(seconds: mode.cycleDuration);
                          Navigator.pop(context);
                      },
                      trailing: context.read<BreathingBloc>().state.mode == mode 
                        ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
                  ))],
              ),
          )
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
                    Text("Session Duration", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 24),
                    ...durations.map((d) => ListTile(
                      title: Text(d == -1 ? 'Infinite' : '$d min'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      onTap: () {
                          context.read<BreathingBloc>().add(ChangeSessionDuration(d));
                          Navigator.pop(context);
                      },
                      trailing: context.read<BreathingBloc>().state.sessionDurationMinutes == d
                        ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
                  ))],
              ),
          )
      );
  }
}
