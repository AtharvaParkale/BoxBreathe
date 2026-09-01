import 'package:equatable/equatable.dart';

class Settings extends Equatable {
  final bool isSoundEnabled;
  final String soundCue;
  final bool isHapticEnabled;
  final int dailyReminderHour; // -1 if disabled
  final int dailyReminderMinute;
  final List<String> favoriteTechniqueIds;

  const Settings({
    required this.isSoundEnabled,
    this.soundCue = 'bell',
    required this.isHapticEnabled,
    this.dailyReminderHour = -1,
    this.dailyReminderMinute = 0,
    this.favoriteTechniqueIds = const [],
  });

  static const defaultSettings = Settings(
    isSoundEnabled: true,
    soundCue: 'bell',
    isHapticEnabled: true,
  );

  Settings copyWith({
    bool? isSoundEnabled,
    String? soundCue,
    bool? isHapticEnabled,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    List<String>? favoriteTechniqueIds,
  }) {
    return Settings(
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      soundCue: soundCue ?? this.soundCue,
      isHapticEnabled: isHapticEnabled ?? this.isHapticEnabled,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
      favoriteTechniqueIds: favoriteTechniqueIds ?? this.favoriteTechniqueIds,
    );
  }

  @override
  List<Object?> get props => [
    isSoundEnabled,
    soundCue,
    isHapticEnabled,
    dailyReminderHour,
    dailyReminderMinute,
    favoriteTechniqueIds,
  ];
}
