import 'package:equatable/equatable.dart';

abstract class ProgressEvent extends Equatable {
  const ProgressEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the local summary immediately, then silently syncs from remote
/// and re-emits if anything new was merged — no spinner-first UX.
class LoadProgress extends ProgressEvent {}

class ChangeDisplayedMonth extends ProgressEvent {
  final DateTime month;
  const ChangeDisplayedMonth(this.month);

  @override
  List<Object?> get props => [month];
}
