import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/services/breathing_audio_handler.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ease_sheet.dart';
import '../../../../core/widgets/lists.dart';
import '../../../../features/progress/presentation/pages/progress_page.dart';
import '../../../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../../../features/settings/presentation/pages/settings_page.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/breathing_pattern.dart';
import '../bloc/breathing_bloc.dart';
import '../bloc/breathing_event.dart';
import '../bloc/breathing_state.dart';
import '../widgets/breathing_orb.dart';
import '../widgets/completion_view.dart';
import '../widgets/home_view.dart';
import '../widgets/moment_picker.dart';
import '../widgets/session_view.dart';
import 'technique_library_page.dart';

/// Root screen. Owns the session lifecycle (animation clock, countdown,
/// audio/haptic cues, wakelock, background reconcile) and renders one of
/// three stage views — home, session (countdown/active/paused), completion
/// — around a single persistent [BreathingOrb].
class BreathingPage extends StatefulWidget {
  const BreathingPage({super.key});

  @override
  State<BreathingPage> createState() => _BreathingPageState();
}

class _BreathingPageState extends State<BreathingPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _breathingController;

  // Countdown State
  bool _isCountingDown = false;
  int _countdownValue = 3;

  /// Bumped on every countdown start/cancel; a running countdown loop bails
  /// out as soon as it sees a token other than its own, so a cancelled
  /// countdown can never dispatch `StartBreathing`.
  int _countdownToken = 0;

  // Haptic State Tracking
  BreathingPhaseKind? _lastPhase;

  /// Active segment index + whole seconds left in it, published only when
  /// they change so the phase text rebuilds a few times per breath rather
  /// than every animation frame.
  final _phaseIndex = ValueNotifier<int>(0);
  final _phaseSecondsLeft = ValueNotifier<int>(0);

  // Audio interruptions (calls, Bluetooth/headphone route changes) reported
  // by the background audio handler — treated exactly like a manual pause.
  StreamSubscription<void>? _audioInterruptionSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioInterruptionSubscription = di
        .sl<BreathingAudioHandler>()
        .onInterruption
        .listen((_) {
          if (mounted &&
              context.read<BreathingBloc>().state.status ==
                  BreathingStatus.active) {
            _pauseSession();
          }
        });
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
    _breathingController.addListener(_onBreathingTick);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _breathingController.removeListener(_onBreathingTick);
    _breathingController.dispose();
    _phaseIndex.dispose();
    _phaseSecondsLeft.dispose();
    _audioInterruptionSubscription?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final bloc = context.read<BreathingBloc>();
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive) &&
        bloc.state.status == BreathingStatus.active) {
      // Stop the local animation only — the session itself keeps running,
      // tracked by wall-clock time in the bloc/persisted snapshot. Calling
      // `_pauseSession()` here would dispatch `PauseBreathing`, which
      // incorrectly freezes elapsed session time while merely backgrounded
      // (as opposed to a real user-initiated pause).
      _breathingController.stop();
    } else if (state == AppLifecycleState.resumed) {
      bloc.add(ReconcileSession());
    }
  }

  void _onBreathingTick() {
    final state = context.read<BreathingBloc>().state;
    final pattern = state.technique.pattern;
    final t = _breathingController.value;
    final phaseInfo = pattern.phaseAt(t);

    final segment = pattern.segmentAt(t);
    _phaseIndex.value = segment.index;
    if (pattern.segments.isNotEmpty) {
      final segMs = pattern.segments[segment.index].durationMs;
      _phaseSecondsLeft.value = ((1 - segment.progress) * segMs / 1000)
          .ceil()
          .clamp(1, 99);
    }

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

  // Background/lock-screen audio presence — only when the user has sound
  // cues enabled (no silent keep-alive). See `BreathingAudioHandler` for why
  // this only configures the audio session + Now Playing card rather than
  // playing its own track.
  void _startAudioSession(BreathingState state) {
    final settings = context.read<SettingsBloc>().state.settings;
    if (!settings.isSoundEnabled) return;
    unawaited(
      di.sl<BreathingAudioHandler>().startSession(
        sessionId: state.activeSessionId ?? 'ease-session',
        techniqueName: state.technique.name,
        sessionDurationMinutes: state.sessionDurationMinutes,
        elapsed: Duration(milliseconds: state.sessionElapsedMs),
      ),
    );
  }

  void _pauseAudioSession(BreathingState state) {
    if (!context.read<SettingsBloc>().state.settings.isSoundEnabled) return;
    unawaited(
      di.sl<BreathingAudioHandler>().pauseSession(
        Duration(milliseconds: state.sessionElapsedMs),
      ),
    );
  }

  void _resumeAudioSession(BreathingState state) {
    if (!context.read<SettingsBloc>().state.settings.isSoundEnabled) return;
    unawaited(
      di.sl<BreathingAudioHandler>().resumeSession(
        Duration(milliseconds: state.sessionElapsedMs),
      ),
    );
  }

  void _endAudioSession() {
    unawaited(di.sl<BreathingAudioHandler>().endSession());
  }

  void _triggerPhaseHaptic() {
    // Double Pulse Haptic
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) HapticFeedback.lightImpact();
    });
  }

  void _selectMoment(MomentOption option) {
    if (_isCountingDown) return;
    final bloc = context.read<BreathingBloc>();
    bloc.add(ChangeTechnique(option.techniqueId, reason: option.reason));
    bloc.add(ChangeSessionDuration(option.durationMinutes));
    _startSession();
  }

  void _startSession() {
    if (_isCountingDown) return;
    setState(() {
      _isCountingDown = true;
      _countdownValue = 3;
    });

    _runCountdown(++_countdownToken);
  }

  void _cancelCountdown() {
    _countdownToken++;
    setState(() => _isCountingDown = false);
  }

  void _runCountdown(int token) async {
    final settings = context.read<SettingsBloc>().state.settings;
    for (int i = 3; i > 0; i--) {
      if (!mounted || token != _countdownToken) return;
      setState(() => _countdownValue = i);

      // Play Sound if enabled
      if (settings.isSoundEnabled) {
        di.sl<SoundService>().playPhaseSound(settings.soundCue);
      }

      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted || token != _countdownToken) return;

    setState(() {
      _isCountingDown = false;
    });

    // Start Breathing Animation & BLoC Timer
    final bloc = context.read<BreathingBloc>();
    final technique = bloc.state.technique;
    _breathingController.duration = Duration(
      milliseconds: technique.pattern.cycleDurationMs,
    );
    _breathingController.repeat();
    _startAudioSession(bloc.state);
    bloc.add(StartBreathing());
  }

  void _pauseSession() {
    _breathingController.stop();
    _pauseAudioSession(context.read<BreathingBloc>().state);
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

    _resumeAudioSession(context.read<BreathingBloc>().state);
    context.read<BreathingBloc>().add(ResumeBreathing());
  }

  /// Ends an in-progress session without logging it (same semantics as the
  /// previous "reset" control).
  void _stopSession() {
    _endAudioSession();
    context.read<BreathingBloc>().add(StopBreathing());
  }

  void _dismissCompletion() {
    context.read<BreathingBloc>().add(StopBreathing());
  }

  void _breatheAgain() {
    context.read<BreathingBloc>().add(StopBreathing());
    _startSession();
  }

  // ── Navigation ────────────────────────────────────────────────────────

  /// Library/detail pop with `true` when the user tapped Begin there —
  /// start straight away instead of making them press Begin twice.
  Future<void> _openLibrary() async {
    final start = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TechniqueLibraryPage()),
    );
    if (start == true && mounted) _startSession();
  }

  Future<void> _openProgress() async {
    final start = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProgressPage()),
    );
    if (start == true && mounted) _startSession();
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  void _showDurationSelector() {
    final bloc = context.read<BreathingBloc>();
    final durations = bloc.state.technique.availableDurations;
    final hapticsEnabled = context
        .read<SettingsBloc>()
        .state
        .settings
        .isHapticEnabled;
    showEaseSheet<void>(
      context: context,
      title: 'Duration',
      builder: (sheetContext) => HairlineList(
        children: [
          for (final d in durations)
            ListRow(
              title: formatDurationChoice(d),
              hapticsEnabled: hapticsEnabled,
              trailing: SelectedMark(
                selected: bloc.state.sessionDurationMinutes == d,
              ),
              onTap: () {
                bloc.add(ChangeSessionDuration(d));
                Navigator.pop(sheetContext);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _confirmLeaveSession() async {
    final end = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End this session?'),
        content: const Text("It won't be saved to your progress."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('End'),
          ),
        ],
      ),
    );
    if (end == true && mounted) _stopSession();
  }

  // ── Build ─────────────────────────────────────────────────────────────

  void _onStateChanged(BuildContext context, BreathingState state) {
    if (state.status == BreathingStatus.active) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }

    if (state.justReconciled &&
        (state.status == BreathingStatus.active ||
            state.status == BreathingStatus.paused)) {
      // Re-anchor the visual animation to the bloc's authoritative
      // elapsed time — this is the one place the UI is allowed to seed
      // itself from session time, and only at this single discontinuity
      // (session start/resume have their own seeding already; this
      // covers "returned from background/relaunch").
      final cycleMs = state.technique.pattern.cycleDurationMs;
      final t = cycleMs <= 0
          ? 0.0
          : (state.sessionElapsedMs % cycleMs) / cycleMs;
      _breathingController.duration = Duration(milliseconds: cycleMs);
      // Silently re-sync the last-seen phase — do NOT fire a catch-up
      // sound/haptic for whatever phase changes happened while away.
      _lastPhase = state.technique.pattern.phaseAt(t).phase;
      _breathingController.value = t;
      // Re-publish Now Playing info unconditionally first — covers a
      // cold start straight into a paused session, where no prior
      // `startSession` call ever ran to set the MediaItem.
      _startAudioSession(state);
      if (state.status == BreathingStatus.active) {
        _breathingController.forward(from: t).whenComplete(() {
          if (context.read<BreathingBloc>().state.status ==
              BreathingStatus.active) {
            _breathingController.repeat();
          }
        });
      } else {
        _pauseAudioSession(state);
      }
      return;
    }

    if (state.status == BreathingStatus.completed) {
      _endAudioSession();
      _breathingController.stop();
      if (context.read<SettingsBloc>().state.settings.isHapticEnabled) {
        HapticFeedback.heavyImpact();
      }
      // Let the orb settle back to rest. The completion view stays until
      // the user dismisses it — no auto-timeout.
      _breathingController.animateTo(
        0.0,
        duration: AppMotion.of(context, const Duration(seconds: 2)),
        curve: AppMotion.standard,
      );
    } else if (state.status == BreathingStatus.initial) {
      _breathingController.reset();
      _breathingController.value = 0.0;
      _lastPhase = null;
    } else if (state.technique.pattern.cycleDurationMs !=
        _breathingController.duration?.inMilliseconds) {
      // Technique changed
      _breathingController.duration = Duration(
        milliseconds: state.technique.pattern.cycleDurationMs,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BreathingBloc, BreathingState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.technique != current.technique ||
          current.justReconciled,
      listener: _onStateChanged,
      child: BlocSelector<BreathingBloc, BreathingState, BreathingStatus>(
        selector: (state) => state.status,
        builder: (context, status) {
          final inSession =
              _isCountingDown ||
              status == BreathingStatus.active ||
              status == BreathingStatus.paused;
          final hapticsEnabled = context.select(
            (SettingsBloc bloc) => bloc.state.settings.isHapticEnabled,
          );
          final pattern = context.select(
            (BreathingBloc bloc) => bloc.state.technique.pattern,
          );

          final OrbMode orbMode;
          if (_isCountingDown || status == BreathingStatus.initial) {
            orbMode = OrbMode.rest;
          } else if (status == BreathingStatus.active) {
            orbMode = OrbMode.breathing;
          } else if (status == BreathingStatus.paused) {
            orbMode = OrbMode.paused;
          } else {
            orbMode = OrbMode.follow;
          }

          final Widget stage;
          final String stageKey;
          if (inSession) {
            stageKey = 'session';
            stage = SessionView(
              isCountingDown: _isCountingDown,
              phaseIndex: _phaseIndex,
              phaseSecondsLeft: _phaseSecondsLeft,
              hapticsEnabled: hapticsEnabled,
              onPause: _pauseSession,
              onResume: _resumeSession,
              onStop: _stopSession,
              onCancelCountdown: _cancelCountdown,
            );
          } else if (status == BreathingStatus.completed) {
            stageKey = 'completed';
            stage = CompletionView(
              hapticsEnabled: hapticsEnabled,
              onDone: _dismissCompletion,
              onAgain: _breatheAgain,
            );
          } else {
            stageKey = 'home';
            stage = HomeView(
              hapticsEnabled: hapticsEnabled,
              onBegin: _startSession,
              onOpenLibrary: _openLibrary,
              onOpenDuration: _showDurationSelector,
              onSelectMoment: _selectMoment,
            );
          }

          return PopScope(
            canPop: !inSession,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              if (_isCountingDown) {
                _cancelCountdown();
              } else {
                _confirmLeaveSession();
              }
            },
            child: Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    SizedBox(
                      height: 56,
                      child: AnimatedSwitcher(
                        duration: AppMotion.of(context, AppMotion.base),
                        child: inSession
                            ? const SessionHeader(key: ValueKey('session'))
                            : status == BreathingStatus.completed
                            ? const SizedBox.shrink()
                            : HomeHeader(
                                key: const ValueKey('home'),
                                hapticsEnabled: hapticsEnabled,
                                onOpenLibrary: _openLibrary,
                                onOpenProgress: _openProgress,
                                onOpenSettings: _openSettings,
                              ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = (constraints.biggest.shortestSide - 16)
                              .clamp(160.0, 320.0);
                          return Center(
                            child: Semantics(
                              image: true,
                              label: 'Breathing guide',
                              child: BreathingOrb(
                                cycle: _breathingController,
                                pattern: pattern,
                                mode: orbMode,
                                size: size,
                                center: _isCountingDown
                                    ? CountdownNumeral(value: _countdownValue)
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    AnimatedSize(
                      duration: AppMotion.of(context, AppMotion.calm),
                      curve: AppMotion.standard,
                      alignment: Alignment.topCenter,
                      child: AnimatedSwitcher(
                        duration: AppMotion.of(context, AppMotion.calm),
                        switchInCurve: AppMotion.enter,
                        switchOutCurve: AppMotion.exit,
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.topCenter,
                          children: [...previous, ?current],
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(stageKey),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.gutter,
                              AppSpacing.xl,
                              AppSpacing.gutter,
                              AppSpacing.lg,
                            ),
                            child: stage,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
