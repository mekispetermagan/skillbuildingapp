import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/l10n/app_localizations.dart';
import 'package:skillbuilding_game/models/activity_id.dart';
import 'package:skillbuilding_game/screens/rating_screen.dart';

void main() {
  testWidgets('offers five stars and reports the selected rating', (
    tester,
  ) async {
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: RatingScreen(
          activity: ActivityId.letterShooting,
          onRate: (rating) async => selected = rating,
        ),
      ),
    );

    expect(find.byIcon(Icons.star), findsNWidgets(5));
    expect(find.text('How much did you like this game?'), findsOneWidget);

    await tester.tap(find.byTooltip('4 out of 5 stars'));
    expect(selected, 4);
  });
}
