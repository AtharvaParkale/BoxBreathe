import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/sound_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/ease_page.dart';
import '../../../../core/widgets/ease_sheet.dart';
import '../../../../core/widgets/lists.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/widgets/account_section.dart';
import '../../domain/entities/settings.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event_state.dart';

/// Sound cue ids (persisted) → display names, in presentation order.
const _soundCues = [
  ('bell', 'Soft bell'),
  ('wood', 'Wooden click'),
  ('air', 'Air tone'),
  ('chime', 'Gentle chime'),
  ('tick', 'Digital tick'),
  ('bowl', 'Tibetan bowl'),
  ('gong', 'Deep gong'),
  ('crystal', 'Crystal bowl'),
  ('rain', 'Rain drop'),
  ('ocean', 'Ocean wave'),
];

String _soundCueName(String id) => _soundCues
    .firstWhere((c) => c.$1 == id, orElse: () => (id, 'Soft bell'))
    .$2;

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final settings = state.settings;
        final bloc = context.read<SettingsBloc>();
        final reminderOn = settings.dailyReminderHour != -1;

        return EasePage(
          title: 'Settings',
          slivers: [
            GutterSliver(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionLabel('During a session', first: true),
                  HairlineList(
                    children: [
                      ToggleRow(
                        title: 'Sound cues',
                        subtitle:
                            'A soft cue at each phase. Best with earphones.',
                        value: settings.isSoundEnabled,
                        onChanged: (v) => bloc.add(ToggleSound(v)),
                      ),
                      if (settings.isSoundEnabled)
                        ListRow(
                          title: 'Sound',
                          value: _soundCueName(settings.soundCue),
                          hapticsEnabled: settings.isHapticEnabled,
                          onTap: () => _pickSoundCue(context, settings),
                        ),
                      ToggleRow(
                        title: 'Haptics',
                        subtitle: 'A gentle tap at each phase.',
                        value: settings.isHapticEnabled,
                        onChanged: (v) => bloc.add(ToggleHaptic(v)),
                      ),
                    ],
                  ),

                  const SectionLabel('Reminder'),
                  HairlineList(
                    children: [
                      ToggleRow(
                        title: 'Daily reminder',
                        subtitle: 'One quiet nudge a day.',
                        value: reminderOn,
                        onChanged: (on) => on
                            ? _pickTime(context, settings)
                            : bloc.add(CancelDailyReminder()),
                      ),
                      if (reminderOn)
                        ListRow(
                          title: 'Time',
                          value: formatTimeOfDay(
                            settings.dailyReminderHour,
                            settings.dailyReminderMinute,
                          ),
                          hapticsEnabled: settings.isHapticEnabled,
                          onTap: () => _pickTime(context, settings),
                        ),
                    ],
                  ),

                  const SectionLabel('Account'),
                  const AccountSection(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _pickSoundCue(BuildContext context, Settings settings) {
    final bloc = context.read<SettingsBloc>();
    showEaseSheet<void>(
      context: context,
      title: 'Sound',
      builder: (sheetContext) => BlocBuilder<SettingsBloc, SettingsState>(
        bloc: bloc,
        buildWhen: (a, b) => a.settings.soundCue != b.settings.soundCue,
        builder: (_, state) => HairlineList(
          children: [
            for (final (id, name) in _soundCues)
              ListRow(
                title: name,
                hapticsEnabled: settings.isHapticEnabled,
                trailing: SelectedMark(selected: state.settings.soundCue == id),
                // Selecting previews the sound; the sheet stays open so
                // cues can be compared.
                onTap: () {
                  bloc.add(ChangeSoundCue(id));
                  sl<SoundService>().playPhaseSound(id);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, Settings settings) async {
    final picked = await showTimePicker(
      context: context,
      helpText: 'Remind me at',
      initialTime: settings.dailyReminderHour == -1
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay(
              hour: settings.dailyReminderHour,
              minute: settings.dailyReminderMinute,
            ),
    );

    if (picked != null && context.mounted) {
      context.read<SettingsBloc>().add(
        SetDailyReminder(picked.hour, picked.minute),
      );
    }
  }
}
