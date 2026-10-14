import 'package:box_breathe/features/breathing/presentation/bloc/breathing_state.dart';
import 'package:box_breathe/features/progress/presentation/bloc/progress_state.dart';
import 'package:box_breathe/features/progress/presentation/pages/progress_page.dart';
import 'package:box_breathe/features/settings/presentation/bloc/settings_event_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/ui_harness.dart';
import 'progress_fixtures.dart';

void main() {
  late MockBreathingBloc breathing;
  late MockSettingsBloc settings;

  setUpAll(registerUiFallbacks);

  setUp(() {
    breathing = MockBreathingBloc()..stubState(BreathingState.initial());
    settings = MockSettingsBloc()
      ..stubState(const SettingsState(settings: quietSettings));
  });

  testWidgets('empty history shows a specific empty state', (tester) async {
    await installFakeServices(
      progressBloc: () => MockProgressBloc()
        ..stubState(ProgressState(isLoading: false, summary: emptySummary())),
    );
    await tester.pumpWidget(
      wrapWithApp(
        const ProgressPage(),
        breathing: breathing,
        settings: settings,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nothing here yet.'), findsOneWidget);
    expect(find.text('Begin a session'), findsOneWidget);
  });

  testWidgets('populated progress shows streak, stats and recent sessions', (
    tester,
  ) async {
    await installFakeServices(
      recent: recentRecords(),
      progressBloc: () => MockProgressBloc()
        ..stubState(ProgressState(isLoading: false, summary: fullSummary())),
    );
    await tester.pumpWidget(
      wrapWithApp(
        const ProgressPage(),
        breathing: breathing,
        settings: settings,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5'), findsWidgets);
    expect(find.text('days in a row'), findsOneWidget);
    expect(find.text('1h 4m'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('RECENT SESSIONS'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('RECENT SESSIONS'), findsOneWidget);
  });
}
