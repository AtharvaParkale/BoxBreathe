import 'package:equatable/equatable.dart';
import '../../domain/entities/breathing_mode.dart';
import '../../domain/entities/breathing_settings.dart';

abstract class BreathingEvent extends Equatable {
  const BreathingEvent();

  @override
  List<Object> get props => [];
}

class LoadBreathingSettings extends BreathingEvent {}

class StartBreathing extends BreathingEvent {}

class PauseBreathing extends BreathingEvent {}

class ResumeBreathing extends BreathingEvent {}

class StopBreathing extends BreathingEvent {}

class ChangeBreathingMode extends BreathingEvent {
  final BreathingMode mode;
  const ChangeBreathingMode(this.mode);

  @override
  List<Object> get props => [mode];
}

class ChangeSessionDuration extends BreathingEvent {
  final int durationMinutes;
  const ChangeSessionDuration(this.durationMinutes);

  @override
  List<Object> get props => [durationMinutes];
}

class TimerTick extends BreathingEvent {
  final int sessionRemaining;

  const TimerTick({required this.sessionRemaining});

  @override
  List<Object> get props => [sessionRemaining];
}
