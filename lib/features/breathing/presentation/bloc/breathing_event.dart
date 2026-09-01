import 'package:equatable/equatable.dart';

abstract class BreathingEvent extends Equatable {
  const BreathingEvent();

  @override
  List<Object?> get props => [];
}

class LoadBreathingSettings extends BreathingEvent {}

class StartBreathing extends BreathingEvent {}

class PauseBreathing extends BreathingEvent {}

class ResumeBreathing extends BreathingEvent {}

class StopBreathing extends BreathingEvent {}

class ChangeTechnique extends BreathingEvent {
  final String techniqueId;

  /// Why this technique was picked this time (e.g. 'calm', 'sleep'),
  /// carried through to session analytics. Null when picked directly
  /// rather than via a need-based entry point.
  final String? reason;

  const ChangeTechnique(this.techniqueId, {this.reason});

  @override
  List<Object?> get props => [techniqueId, reason];
}

class ChangeSessionDuration extends BreathingEvent {
  final int durationMinutes;
  const ChangeSessionDuration(this.durationMinutes);

  @override
  List<Object> get props => [durationMinutes];
}

class TimerTick extends BreathingEvent {}
