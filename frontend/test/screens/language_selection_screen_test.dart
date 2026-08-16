import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/models/interface_language.dart';
import 'package:literacy_game/screens/language_selection_screen.dart';

void main() {
  testWidgets('offers separate native-name language buttons', (tester) async {
    InterfaceLanguage? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: LanguageSelectionScreen(
          onSelect: (language) => selected = language,
        ),
      ),
    );

    expect(find.text('English'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('Magyar'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('English')).dy,
      lessThan(tester.getTopLeft(find.text('Deutsch')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Deutsch')).dy,
      lessThan(tester.getTopLeft(find.text('Magyar')).dy),
    );

    await tester.tap(find.text('Magyar'));
    expect(selected, InterfaceLanguage.hungarian);
  });
}
