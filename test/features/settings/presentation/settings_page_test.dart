import 'package:box_breathe/features/breathing/presentation/bloc/breathing_state.dart';
import 'package:box_breathe/features/settings/presentation/bloc/settings_event_state.dart';
import 'package:box_breathe/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/ui_harness.dart';

void main() {
  late MockBreathingBloc breathing;
  late MockSettingsBloc settings;

  setUpAll(registerUiFallbacks);

  setUp(() async {
    await installFakeServices();
    breathing = MockBreathingBloc()..stubState(BreathingState.initial());
    settings = MockSettingsBloc();
  });

  testWidgets('turning the daily reminder off cancels it', (tester) async {
    settings.stubState(
      SettingsState(
        settings: quietSettings.copyWith(
          dailyReminderHour: 21,
          dailyReminderMinute: 30,
        ),
      ),
    );
    await tester.pumpWidget(
      wrapWithApp(
        const SettingsPage(),
        breathing: breathing,
        settings: settings,
      ),
    );

    expect(find.text('9:30 PM'), findsOneWidget);
    await tester.tap(find.text('Daily reminder'));
    verify(() => settings.add(any(that: isA<CancelDailyReminder>()))).called(1);
  });

  testWidgets('sound choice row only appears when cues are on', (tester) async {
    settings.stubState(const SettingsState(settings: quietSettings));
    await tester.pumpWidget(
      wrapWithApp(
        const SettingsPage(),
        breathing: breathing,
        settings: settings,
      ),
    );
    expect(find.text('Sound'), findsNothing);

    await tester.tap(find.text('Haptics'));
    verify(() => settings.add(any(that: isA<ToggleHaptic>()))).called(1);
  });

  testWidgets('settings meets tap-target and label guidelines', (tester) async {
    settings.stubState(const SettingsState());
    await tester.pumpWidget(
      wrapWithApp(
        const SettingsPage(),
        breathing: breathing,
        settings: settings,
      ),
    );
    await tester.pump();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(find.byType(Switch), findsNWidgets(3));
  });
}
