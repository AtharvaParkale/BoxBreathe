import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
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
            onPressed: () => Navigator.pop(context)),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final settings = state.settings;
          
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionHeader(context, 'APPEARANCE'),
              const SizedBox(height: 12),
              _buildThemeSelector(context, settings),
              const SizedBox(height: 32),
              
              _buildSectionHeader(context, 'PREFERENCES'),
              const SizedBox(height: 12),
              _buildGroupContainer(
                context,
                children: [
                   SwitchListTile(
                     contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
                     contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
               
               const SizedBox(height: 32),
               _buildSectionHeader(context, 'REMINDERS'),
               const SizedBox(height: 12),
               _buildGroupContainer(
                 context,
                 children: [
                   ListTile(
                     contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                     title: const Text('Daily Reminder'),
                     subtitle: Text(settings.dailyReminderHour == -1 
                         ? 'Off' 
                         : _formatTime(settings.dailyReminderHour, settings.dailyReminderMinute)),
                     trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8)
                        ),
                        child: const Icon(Icons.access_time_rounded, size: 20)
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

  Widget _buildGroupContainer(BuildContext context, {required List<Widget> children}) {
      return Container(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
              children: children,
          ),
      );
  }

  Widget _buildDivider(BuildContext context) {
      return Divider(
          height: 1, 
          indent: 20, 
          endIndent: 20, 
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2)
      );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, dynamic settings) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppThemeMode.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
            final mode = AppThemeMode.values[index];
            final isSelected = settings.themeMode == mode;
            
            return GestureDetector(
                onTap: () => context.read<SettingsBloc>().add(ChangeTheme(mode)),
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isSelected ? 60 : 50,
                    height: isSelected ? 60 : 50,
                    decoration: BoxDecoration(
                        color: _getThemeColor(mode),
                        shape: BoxShape.circle,
                        border: isSelected 
                            ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                            : Border.all(color: Colors.transparent),
                        boxShadow: isSelected ? [
                            BoxShadow(
                                color: _getThemeColor(mode).withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                            )
                        ] : [],
                    ),
                    child: isSelected 
                        ? Icon(Icons.check, color: _getContrastColor(mode), size: 18) 
                        : null,
                ),
            );
        },
      ),
    );
  }

  Color _getContrastColor(AppThemeMode mode) {
      switch (mode) {
          case AppThemeMode.midnight: return Colors.white;
          case AppThemeMode.ocean: return Colors.white;
          case AppThemeMode.forest: return Colors.white;
          case AppThemeMode.lavender: return Colors.black;
          case AppThemeMode.sand: return Colors.black;
          case AppThemeMode.minimalLight: return Colors.black;
      }
  }

  Color _getThemeColor(AppThemeMode mode) {
      switch (mode) {
        case AppThemeMode.midnight: return Colors.black;
        case AppThemeMode.ocean: return const Color(0xFF0F172A);
        case AppThemeMode.forest: return const Color(0xFF1A1C19);
        case AppThemeMode.lavender: return const Color(0xFFF3E5F5);
        case AppThemeMode.sand: return const Color(0xFFF5F5DC);
        case AppThemeMode.minimalLight: return const Color(0xFFFAFAFA);
      }
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
             : TimeOfDay(hour: settings.dailyReminderHour, minute: settings.dailyReminderMinute),
         builder: (context, child) {
             return Theme(
                 data: Theme.of(context).copyWith(
                     timePickerTheme: TimePickerThemeData(
                         dialBackgroundColor: Theme.of(context).colorScheme.surface,
                     )
                 ),
                 child: child!,
             );
         }
       );

       if (picked != null) {
         context.read<SettingsBloc>().add(SetDailyReminder(picked.hour, picked.minute));
       }
  }
}
