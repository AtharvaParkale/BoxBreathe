import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/breathing_bloc.dart';
import '../bloc/breathing_event.dart';
import '../bloc/breathing_state.dart';
import '../../domain/entities/breathing_mode.dart';
import '../../../../features/settings/presentation/pages/settings_page.dart';

class BreathingPage extends StatefulWidget {
  const BreathingPage({super.key});

  @override
  State<BreathingPage> createState() => _BreathingPageState();
}

class _BreathingPageState extends State<BreathingPage>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), 
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubicEmphasized),
    );
    
    _glowController = AnimationController(
        vsync: this, 
        duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOutQuad)
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BreathingBloc, BreathingState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.currentPhase != current.currentPhase,
      listener: (context, state) {
        if (state.status == BreathingStatus.initial) {
          _animController.reset();
        } else if (state.status == BreathingStatus.paused) {
          _animController.stop();
        } else if (state.status == BreathingStatus.completed) {
          _animController.stop();
        } else if (state.status == BreathingStatus.active) {
          int durationSeconds = 0;
          double targetValue = 0.0;

          switch (state.currentPhase) {
            case BreathingPhase.inhale:
              durationSeconds = state.mode.inhaleDuration;
              targetValue = 1.0; 
              break;
            case BreathingPhase.holdFull:
              durationSeconds = state.mode.holdFullDuration;
              targetValue = 1.0; 
              break;
            case BreathingPhase.exhale:
              durationSeconds = state.mode.exhaleDuration;
              targetValue = 0.0; 
              break;
            case BreathingPhase.holdEmpty:
              durationSeconds = state.mode.holdEmptyDuration;
              targetValue = 0.0; 
              break;
          }

          if (durationSeconds > 0) {
             if (state.currentPhase == BreathingPhase.inhale || state.currentPhase == BreathingPhase.exhale) {
                 _animController.animateTo(
                    targetValue,
                    duration: Duration(seconds: durationSeconds),
                    curve: Curves.easeInOutCubicEmphasized,
                 );
             }
          }
        }
      },
      builder: (context, state) {
        final theme = Theme.of(context);
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
                        onTap: () => _showModeSelector(context),
                      ),
                      _buildMinimalButton(
                        context, 
                        icon: Icons.timer_rounded, 
                        onTap: () => _showDurationSelector(context),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Breathing Shape
                      AnimatedBuilder(
                        animation: Listenable.merge([_scaleAnimation, _glowAnimation]),
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.9),
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
                          );
                        },
                      ),
                      
                      const SizedBox(height: 80),
                      
                      // Animated Phase Text
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          state.phaseLabel.toUpperCase(),
                          key: ValueKey(state.phaseLabel),
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
                  ),
                ),
                
                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: GestureDetector(
                    onTap: () {
                      if (state.status == BreathingStatus.active) {
                        context.read<BreathingBloc>().add(PauseBreathing());
                      } else if (state.status == BreathingStatus.paused) {
                         context.read<BreathingBloc>().add(ResumeBreathing());
                      } else {
                         context.read<BreathingBloc>().add(StartBreathing());
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

  Widget _buildMinimalButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
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
        child: Icon(icon, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
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
