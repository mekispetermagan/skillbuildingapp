import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/l10n/app_localizations.dart';
import 'package:literacy_game/widgets/lives_display.dart';

void main() {
  testWidgets('renders remaining and lost lives with reusable SVG images', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: LivesDisplay(lives: 3, maximumLives: 5)),
      ),
    );

    expect(find.byKey(const ValueKey('life-good-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('life-good-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('life-good-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('life-bad-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('life-bad-4')), findsOneWidget);
    expect(find.bySemanticsLabel('3 of 5 lives remaining'), findsOneWidget);
  });
}
