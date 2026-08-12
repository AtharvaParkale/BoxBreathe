import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_containers.dart';
import '../../../history/domain/entities/session_history.dart';
import '../../../history/domain/usecases/get_history.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final settings = state.settings;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const AppSectionHeader(title: 'PREFERENCES'),
              const SizedBox(height: AppSpacing.sm2),
              AppGroupContainer(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    title: const Text('Sounds'),
                    subtitle: const Text('Play soft sounds during breathing'),
                    value: settings.isSoundEnabled,
                    activeTrackColor: Theme.of(context).primaryColor,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(ToggleSound(value));
                    },
                  ),
                  const AppDivider(),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    title: const Text('Haptics'),
                    subtitle: const Text('Vibrate on phase changes'),
                    value: settings.isHapticEnabled,
                    activeTrackColor: Theme.of(context).primaryColor,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(ToggleHaptic(value));
                    },
                  ),
                ],
              ),

              if (settings.isSoundEnabled) ...[
                const SizedBox(height: AppSpacing.xxl),
                const AppSectionHeader(title: 'SOUND CUE'),
                const SizedBox(height: AppSpacing.sm2),
                AppGroupContainer(
                  children: [
                    _buildSoundCueOption(context, settings, 'Soft Bell', 'bell'),
                    const AppDivider(),
                    _buildSoundCueOption(context, settings, 'Wooden Click', 'wood'),
                    const AppDivider(),
                    _buildSoundCueOption(context, settings, 'Air Tone', 'air'),
                    const AppDivider(),
                    _buildSoundCueOption(context, settings, 'Gentle Chime', 'chime'),
                    const AppDivider(),
                    _buildSoundCueOption(context, settings, 'Digital Tick', 'tick'),
                    const AppDivider(),
                    _buildSoundCueOption(context, settings, 'Tibetan Bowl', 'bowl'),
                    const AppDivider(),
                    _buildSoundCueOption(context, settings, 'Deep Gong', 'gong'),
                    const AppDivider(),
                    _buildSoundCueOption(context, settings, 'Crystal Bowl', 'crystal'),
                    const AppDivider(),
                    _buildSoundCueOption(context, settings, 'Rain Drop', 'rain'),
                    const AppDivider(),
                    _buildSoundCueOption(context, settings, 'Ocean Wave', 'ocean'),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.xxl),
              const AppSectionHeader(title: 'REMINDERS'),
              const SizedBox(height: AppSpacing.sm2),
              AppGroupContainer(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    title: const Text('Daily Reminder'),
                    subtitle: Text(
                      settings.dailyReminderHour == -1
                          ? 'Off'
                          : _formatTime(
                              settings.dailyReminderHour,
                              settings.dailyReminderMinute,
                            ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 1,
                        ),
                      ),
                      child: const Icon(Icons.access_time_rounded, size: 20),
                    ),
                    onTap: () => _pickTime(context, settings),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xxl),
              const AppSectionHeader(title: 'YOUR PRACTICE'),
              const SizedBox(height: AppSpacing.sm2),
              FutureBuilder<SessionHistory>(
                future: sl<GetHistory>()().then(
                  (result) => result.fold((_) => SessionHistory.empty, (h) => h),
                ),
                builder: (context, snapshot) {
                  final history = snapshot.data ?? SessionHistory.empty;
                  return AppGroupContainer(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        title: Text(
                          history.totalSessions == 0
                              ? 'No sessions yet'
                              : '${history.totalSessions} session${history.totalSessions == 1 ? '' : 's'} completed',
                        ),
                        subtitle: Text(
                          '${_formatTotalTime(history.totalSeconds)} of breathing, total',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTotalTime(int totalSeconds) {
    final totalMinutes = totalSeconds ~/ 60;
    if (totalMinutes < 60) return '$totalMinutes min';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
  }

  Widget _buildSoundCueOption(
    BuildContext context,
    dynamic settings,
    String title,
    String value,
  ) {
    final isSelected = settings.soundCue == value;
    final primaryColor = Theme.of(context).primaryColor;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? primaryColor : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: primaryColor)
          : Icon(
              Icons.circle_outlined,
              size: 24,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
            ),
      onTap: () {
        context.read<SettingsBloc>().add(ChangeSoundCue(value));
        sl<SoundService>().playPhaseSound(value);
      },
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  Future<void> _pickTime(BuildContext context, dynamic settings) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: settings.dailyReminderHour == -1
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay(
              hour: settings.dailyReminderHour,
              minute: settings.dailyReminderMinute,
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              dialBackgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      context.read<SettingsBloc>().add(
        SetDailyReminder(picked.hour, picked.minute),
      );
    }
  }
}
