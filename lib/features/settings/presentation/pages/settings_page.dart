import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../../core/services/sound_service.dart';
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
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionHeader(context, 'PREFERENCES'),
              const SizedBox(height: 12),
              _buildGroupContainer(
                context,
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    title: const Text('Sounds'),
                    subtitle: const Text('Play soft sounds during breathing'),
                    value: settings.isSoundEnabled,
                    activeTrackColor: Theme.of(context).primaryColor,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(ToggleSound(value));
                    },
                  ),
                  _buildDivider(context),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
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
                const SizedBox(height: 32),
                _buildSectionHeader(context, 'SOUND CUE'),
                const SizedBox(height: 12),
                _buildGroupContainer(
                  context,
                  children: [
                    _buildSoundCueOption(context, settings, 'Soft Bell', 'bell'),
                    _buildDivider(context),
                    _buildSoundCueOption(context, settings, 'Wooden Click', 'wood'),
                    _buildDivider(context),
                    _buildSoundCueOption(context, settings, 'Air Tone', 'air'),
                    _buildDivider(context),
                    _buildSoundCueOption(context, settings, 'Gentle Chime', 'chime'),
                    _buildDivider(context),
                    _buildSoundCueOption(context, settings, 'Digital Tick', 'tick'),
                    _buildDivider(context),
                    _buildSoundCueOption(context, settings, 'Tibetan Bowl', 'bowl'),
                    _buildDivider(context),
                    _buildSoundCueOption(context, settings, 'Deep Gong', 'gong'),
                    _buildDivider(context),
                    _buildSoundCueOption(context, settings, 'Crystal Bowl', 'crystal'),
                    _buildDivider(context),
                    _buildSoundCueOption(context, settings, 'Rain Drop', 'rain'),
                    _buildDivider(context),
                    _buildSoundCueOption(context, settings, 'Ocean Wave', 'ocean'),
                  ],
                ),
              ],

              const SizedBox(height: 32),
              _buildSectionHeader(context, 'REMINDERS'),
              const SizedBox(height: 12),
              _buildGroupContainer(
                context,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
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
                      padding: const EdgeInsets.all(8),
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
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupContainer(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(title, style: Theme.of(context).textTheme.labelSmall),
    );
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
