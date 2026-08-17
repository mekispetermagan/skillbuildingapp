import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/main.dart';

void main() {
  testWidgets('opens letter dragging from the activity menu', (tester) async {
    await tester.pumpWidget(const LiteracyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Literacy'));
    await tester.pumpAndSettle();

    expect(find.text('Sentence building'), findsOneWidget);
    expect(find.text('Letter dragging'), findsOneWidget);

    await tester.drag(find.byType(GridView), const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Letter dragging'));
    await tester.pumpAndSettle();

    expect(find.text('Put the letters in the right order'), findsOneWidget);
    expect(find.text('Pass'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('temporarily skips language selection and defaults to English', (
    tester,
  ) async {
    await tester.pumpWidget(const LiteracyApp());
    await tester.pumpAndSettle();

    expect(find.text('English'), findsNothing);
    expect(find.text('Magyar'), findsNothing);
    expect(find.text('Deutsch'), findsNothing);
    expect(find.text('Literacy'), findsOneWidget);
    expect(find.text('Math'), findsOneWidget);
    expect(find.text('Sentence building'), findsNothing);
  });

  testWidgets('opens number learning from the math menu', (tester) async {
    await tester.pumpWidget(const LiteracyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Math'));
    await tester.pumpAndSettle();

    expect(find.text('Number learning'), findsOneWidget);

    await tester.tap(find.text('Number learning'));
    await tester.pumpAndSettle();

    expect(find.text('1–6'), findsOneWidget);
    expect(find.text('Coming soon'), findsNothing);
  });

  testWidgets('opens compare numbers from the math menu', (tester) async {
    await tester.pumpWidget(const LiteracyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Math'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compare numbers'));
    await tester.pumpAndSettle();

    expect(find.text('Pattern'), findsOneWidget);
    expect(find.text('<'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
    expect(find.text('>'), findsOneWidget);
  });

  testWidgets('system back follows the same math navigation hierarchy', (
    tester,
  ) async {
    await tester.pumpWidget(const LiteracyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Math'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Number learning'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Number learning'), findsOneWidget);
    expect(find.text('Operations practice'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Literacy'), findsOneWidget);
    expect(find.text('Math'), findsOneWidget);
  });
}
