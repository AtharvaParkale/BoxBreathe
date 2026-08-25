import 'package:equatable/equatable.dart';

class BreathingSessionRecord extends Equatable {
  final String techniqueId;
  final String techniqueName;
  final int durationSeconds;
  final int completedDurationSeconds;
  final DateTime startedAt;
  final DateTime completedAt;
  final bool completed;

  /// Device platform ('android' | 'ios'). Left null by callers — the remote
  /// data source fills it in at write time, since it's a device property,
  /// not something the breathing session logic should need to know.
  final String? source;

  const BreathingSessionRecord({
    required this.techniqueId,
    required this.techniqueName,
    required this.durationSeconds,
    required this.completedDurationSeconds,
    required this.startedAt,
    required this.completedAt,
    required this.completed,
    this.source,
  });

  @override
  List<Object?> get props => [
    techniqueId,
    techniqueName,
    durationSeconds,
    completedDurationSeconds,
    startedAt,
    completedAt,
    completed,
    source,
  ];
}
