import 'package:equatable/equatable.dart';

class BreathingSettings extends Equatable {
  final String techniqueId;
  final int durationMinutes; // -1 for infinite

  const BreathingSettings({
    required this.techniqueId,
    required this.durationMinutes,
  });

  static const defaultSettings = BreathingSettings(
    techniqueId: 'box', // Default 3 min Box breathing per requirements
    durationMinutes: 3,
  );

  BreathingSettings copyWith({String? techniqueId, int? durationMinutes}) {
    return BreathingSettings(
      techniqueId: techniqueId ?? this.techniqueId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  @override
  List<Object?> get props => [techniqueId, durationMinutes];
}
