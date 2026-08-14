import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/main.dart';

void main() {
  testWidgets('opens letter dragging from the activity menu', (tester) async {
    await tester.pumpWidget(const LiteracyApp());
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    expect(find.text('Magyar'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Sentence building'), findsOneWidget);
    expect(find.text('Letter dragging'), findsOneWidget);

    await tester.tap(find.text('Letter dragging'));
    await tester.pumpAndSettle();

    expect(find.text('Put the letters in the right order'), findsOneWidget);
    expect(find.text('Pass'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('selecting Hungarian opens the localized activity menu', (
    tester,
  ) async {
    await tester.pumpWidget(const LiteracyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Magyar'));
    await tester.pumpAndSettle();

    expect(find.text('Mondatkirakó'), findsOneWidget);
    expect(find.text('Betűrendező'), findsOneWidget);
    expect(find.text('Sentence building'), findsNothing);
  });
}
