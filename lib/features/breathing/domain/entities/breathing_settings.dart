import 'package:equatable/equatable.dart';
import 'breathing_mode.dart';

class BreathingSettings extends Equatable {
  final BreathingMode mode;
  final int durationMinutes; // -1 for infinite

  const BreathingSettings({
    required this.mode,
    required this.durationMinutes,
  });

  static const defaultSettings = BreathingSettings(
    mode: BreathingMode.box, // Default 3 min Box breathing per requirements
    durationMinutes: 3,
  );

  BreathingSettings copyWith({
    BreathingMode? mode,
    int? durationMinutes,
  }) {
    return BreathingSettings(
      mode: mode ?? this.mode,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  @override
  List<Object?> get props => [mode, durationMinutes];
}
