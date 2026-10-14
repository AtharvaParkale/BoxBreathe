import 'package:box_breathe/core/theme/app_theme.dart';
import 'package:box_breathe/core/widgets/ease_button.dart';
import 'package:box_breathe/core/widgets/text_segmented.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.darkTheme,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('quiet button keeps a 44pt+ target and fires', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        EaseButton.quiet(
          label: 'Stop',
          hapticsEnabled: false,
          onTap: () => taps++,
        ),
      ),
    );
    final size = tester.getSize(find.byType(EaseButton));
    expect(size.height, greaterThanOrEqualTo(44));
    await tester.tap(find.text('Stop'));
    expect(taps, 1);
  });

  testWidgets('disabled primary button reports disabled semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const EaseButton.primary(label: 'Begin', onTap: null)),
    );
    expect(
      tester.getSemantics(find.byType(EaseButton)),
      matchesSemantics(
        label: 'Begin',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
  });

  testWidgets('round control is labelled for screen readers', (tester) async {
    await tester.pumpWidget(
      _host(
        RoundControl(
          icon: Icons.pause_rounded,
          semanticLabel: 'Pause session',
          hapticsEnabled: false,
          onTap: () {},
        ),
      ),
    );
    expect(find.bySemanticsLabel('Pause session'), findsOneWidget);
    expect(tester.getSize(find.byType(RoundControl)).width, 72);
  });

  testWidgets('text segmented marks the selection and reports taps', (
    tester,
  ) async {
    int? picked;
    await tester.pumpWidget(
      _host(
        TextSegmented<int>(
          hapticsEnabled: false,
          selected: 3,
          onSelect: (v) => picked = v,
          options: const [(1, '1 min'), (3, '3 min'), (5, '5 min')],
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('3 min')),
      matchesSemantics(
        label: '3 min',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: false,
      ),
    );
    await tester.tap(find.text('5 min'));
    expect(picked, 5);
  });
}
