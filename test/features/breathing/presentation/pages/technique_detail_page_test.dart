import 'package:box_breathe/features/breathing/domain/entities/breathing_technique_catalog.dart';
import 'package:box_breathe/features/breathing/presentation/bloc/breathing_event.dart';
import 'package:box_breathe/features/breathing/presentation/bloc/breathing_state.dart';
import 'package:box_breathe/features/breathing/presentation/pages/technique_detail_page.dart';
import 'package:box_breathe/features/settings/presentation/bloc/settings_event_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/ui_harness.dart';

void main() {
  late MockBreathingBloc breathing;
  late MockSettingsBloc settings;

  setUpAll(registerUiFallbacks);

  setUp(() async {
    await installFakeServices();
    breathing = MockBreathingBloc()..stubState(BreathingState.initial());
    settings = MockSettingsBloc()
      ..stubState(const SettingsState(settings: quietSettings));
  });

  testWidgets('shows how-to steps and safety notes from the catalog', (
    tester,
  ) async {
    final technique = BreathingTechniqueCatalog.calm478;
    await tester.pumpWidget(
      wrapWithApp(
        TechniqueDetailPage(technique: technique),
        breathing: breathing,
        settings: settings,
      ),
    );

    for (final step in technique.instructions) {
      await tester.scrollUntilVisible(find.text(step), 200);
      expect(find.text(step), findsOneWidget);
    }
    for (final warning in technique.warnings) {
      await tester.scrollUntilVisible(find.text(warning), 200);
      expect(find.text(warning), findsOneWidget);
    }
  });

  testWidgets('Begin selects technique + duration and pops with true', (
    tester,
  ) async {
    final technique = BreathingTechniqueCatalog.box;
    bool? popped;
    await tester.pumpWidget(
      wrapWithApp(
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                popped = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TechniqueDetailPage(technique: technique),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
        breathing: breathing,
        settings: settings,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Begin ·'));
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    verify(
      () => breathing.add(
        any(
          that: isA<ChangeTechnique>().having(
            (e) => e.techniqueId,
            'id',
            'box',
          ),
        ),
      ),
    ).called(1);
    verify(
      () => breathing.add(
        any(
          that: isA<ChangeSessionDuration>().having(
            (e) => e.durationMinutes,
            'minutes',
            technique.recommendedDuration,
          ),
        ),
      ),
    ).called(1);
  });
}
