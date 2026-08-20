import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/theme/feature_palette.dart';
import 'package:skillbuilding_game/widgets/feature_menu_grid.dart';

void main() {
  test('feature palette has six distinct schemes and repeats at seven', () {
    final firstCycle = [
      for (var index = 0; index < 6; index++)
        FeaturePalette.schemeForIndex(index).primary,
    ];

    expect(firstCycle.toSet(), hasLength(6));
    expect(
      FeaturePalette.schemeForIndex(6).primary,
      FeaturePalette.schemeForIndex(0).primary,
    );
    expect(
      FeaturePalette.schemeForIndex(12).primary,
      FeaturePalette.schemeForIndex(0).primary,
    );
  });

  testWidgets('feature grid applies palette primary and on-primary colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeatureMenuGrid(
            items: [
              for (var index = 0; index < 6; index++) ('Item $index', () {}),
            ],
          ),
        ),
      ),
    );

    final buttons = tester.widgetList<FilledButton>(find.byType(FilledButton));
    for (final (index, button) in buttons.indexed) {
      final scheme = FeaturePalette.schemeForIndex(index);
      expect(button.style?.backgroundColor?.resolve({}), scheme.primary);
      expect(button.style?.foregroundColor?.resolve({}), scheme.onPrimary);
    }
  });
}
