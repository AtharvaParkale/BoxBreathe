import 'package:box_breathe/features/breathing/presentation/bloc/breathing_event.dart';
import 'package:box_breathe/features/breathing/presentation/bloc/breathing_state.dart';
import 'package:box_breathe/features/breathing/presentation/pages/breathing_page.dart';
import 'package:box_breathe/features/settings/presentation/bloc/settings_event_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/ui_harness.dart';

void main() {
  late MockBreathingBloc breathing;
  late MockSettingsBloc settings;

  setUpAll(registerUiFallbacks);

  setUp(() async {
    await installFakeServices();
    breathing = MockBreathingBloc();
    settings = MockSettingsBloc()
      ..stubState(const SettingsState(settings: quietSettings));
  });

  testWidgets('home shows the invitation, selection and one primary action', (
    tester,
  ) async {
    breathing.stubState(BreathingState.initial());
    await tester.pumpWidget(
      wrapWithApp(
        const BreathingPage(),
        breathing: breathing,
        settings: settings,
      ),
    );

    expect(find.text('Breathe.'), findsOneWidget);
    expect(find.text('Box Breathing'), findsOneWidget);
    expect(find.text('3 min'), findsOneWidget);
    expect(find.text('Begin'), findsOneWidget);
    expect(find.text('Techniques'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
  });

  testWidgets('countdown can be cancelled and never starts the session', (
    tester,
  ) async {
    breathing.stubState(BreathingState.initial());
    await tester.pumpWidget(
      wrapWithApp(
        const BreathingPage(),
        breathing: breathing,
        settings: settings,
      ),
    );

    await tester.tap(find.text('Begin'));
    await tester.pump();
    expect(find.text('Get ready'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    verifyNever(() => breathing.add(any(that: isA<StartBreathing>())));
    expect(find.text('Begin'), findsOneWidget);
  });

  testWidgets('uncancelled countdown starts the session after 3 seconds', (
    tester,
  ) async {
    breathing.stubState(BreathingState.initial());
    await tester.pumpWidget(
      wrapWithApp(
        const BreathingPage(),
        breathing: breathing,
        settings: settings,
      ),
    );

    await tester.tap(find.text('Begin'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 50));

    verify(() => breathing.add(any(that: isA<StartBreathing>()))).called(1);
  });

  testWidgets(
    'active session shows phase, clock and controls; stop dispatches',
    (tester) async {
      breathing.stubState(
        BreathingState(
          status: BreathingStatus.active,
          sessionDurationMinutes: 3,
          sessionRemainingSeconds: 161,
          activeSessionId: 's1',
        ),
      );
      await tester.pumpWidget(
        wrapWithApp(
          const BreathingPage(),
          breathing: breathing,
          settings: settings,
        ),
      );
      await tester.pump();

      expect(find.text('2:41 left'), findsOneWidget);
      expect(find.bySemanticsLabel('Pause session'), findsOneWidget);
      expect(find.text('Begin'), findsNothing);
      expect(
        find.text('Techniques'),
        findsNothing,
        reason: 'nav hidden mid-session',
      );

      await tester.tap(find.text('Stop'));
      verify(() => breathing.add(any(that: isA<StopBreathing>()))).called(1);
    },
  );

  testWidgets('open-ended session shows elapsed time instead of ∞', (
    tester,
  ) async {
    breathing.stubState(
      BreathingState(
        status: BreathingStatus.paused,
        sessionDurationMinutes: -1,
        sessionRemainingSeconds: -1,
        sessionElapsedMs: 75000,
      ),
    );
    await tester.pumpWidget(
      wrapWithApp(
        const BreathingPage(),
        breathing: breathing,
        settings: settings,
      ),
    );
    await tester.pump();

    expect(find.text('1:15 elapsed'), findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);
    expect(find.bySemanticsLabel('Resume session'), findsOneWidget);
  });

  testWidgets('completion stays until dismissed and Done returns home', (
    tester,
  ) async {
    breathing.stubState(
      BreathingState(
        status: BreathingStatus.completed,
        sessionDurationMinutes: 4,
        postSessionStreakDays: 3,
      ),
    );
    await tester.pumpWidget(
      wrapWithApp(
        const BreathingPage(),
        breathing: breathing,
        settings: settings,
      ),
    );
    await tester.pump(const Duration(seconds: 10));

    expect(find.text('Nicely done.'), findsOneWidget);
    expect(find.text('4 minutes of box breathing.'), findsOneWidget);
    expect(find.text('Day 3 in a row'), findsOneWidget);
    verifyNever(() => breathing.add(any(that: isA<StopBreathing>())));

    await tester.tap(find.text('Done'));
    verify(() => breathing.add(any(that: isA<StopBreathing>()))).called(1);
  });

  testWidgets('home has no tap targets under 44pt', (tester) async {
    breathing.stubState(BreathingState.initial());
    await tester.pumpWidget(
      wrapWithApp(
        const BreathingPage(),
        breathing: breathing,
        settings: settings,
      ),
    );
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}
