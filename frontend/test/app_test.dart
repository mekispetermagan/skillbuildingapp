import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:literacy_game/main.dart';

Future<void> pumpStartedApp(WidgetTester tester) async {
  await tester.pumpWidget(const LiteracyApp());
  await tester.pumpAndSettle();

  expect(find.text('Start'), findsOneWidget);
  expect(find.text('Literacy'), findsNothing);

  await tester.tap(find.text('Start'));
  await tester.pumpAndSettle();

  expect(find.text('Literacy'), findsOneWidget);
  expect(find.text('Math'), findsOneWidget);
}

void main() {
  testWidgets('opens letter dragging from the activity menu', (tester) async {
    await pumpStartedApp(tester);

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
    await pumpStartedApp(tester);

    expect(find.text('English'), findsNothing);
    expect(find.text('Magyar'), findsNothing);
    expect(find.text('Deutsch'), findsNothing);
    expect(find.text('Literacy'), findsOneWidget);
    expect(find.text('Math'), findsOneWidget);
    expect(find.text('Sentence building'), findsNothing);
  });

  testWidgets('opens number learning from the math menu', (tester) async {
    await pumpStartedApp(tester);

    await tester.tap(find.text('Math'));
    await tester.pumpAndSettle();

    expect(find.text('Number learning'), findsOneWidget);

    await tester.tap(find.text('Number learning'));
    await tester.pumpAndSettle();

    expect(find.text('1–6'), findsOneWidget);
    expect(find.text('Coming soon'), findsNothing);
  });

  testWidgets('opens compare numbers from the math menu', (tester) async {
    await pumpStartedApp(tester);
    await tester.tap(find.text('Math'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compare numbers'));
    await tester.pumpAndSettle();

    expect(find.text('Pattern'), findsOneWidget);
    expect(find.text('<'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
    expect(find.text('>'), findsOneWidget);
  });

  testWidgets('opens number dragging from the math menu', (tester) async {
    await pumpStartedApp(tester);
    await tester.tap(find.text('Math'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Number dragging'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Number dragging'));
    await tester.pumpAndSettle();

    expect(
      find.text('Put the numbers from smallest to largest'),
      findsOneWidget,
    );
    expect(find.text('1–12'), findsOneWidget);
    expect(find.text('1–24'), findsOneWidget);
    expect(find.text('1–60'), findsOneWidget);
    expect(find.text('Pass'), findsOneWidget);
  });

  testWidgets('opens number memory from the math menu', (tester) async {
    await pumpStartedApp(tester);
    await tester.tap(find.text('Math'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Number memory'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('Number memory'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Number memory'));
    await tester.pumpAndSettle();

    expect(find.text('1–12'), findsOneWidget);
    expect(find.text('1–24'), findsOneWidget);
    expect(find.text('?'), findsNWidgets(18));
  });

  testWidgets('opens the balance game SVG playground', (tester) async {
    await pumpStartedApp(tester);
    await tester.tap(find.text('Math'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Balance game'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('Balance game'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Balance game'));
    await tester.pumpAndSettle();

    expect(find.text('Balance game'), findsOneWidget);
    expect(find.byType(SvgPicture), findsNWidgets(13));
  });

  testWidgets('opens the logic game from the math menu', (tester) async {
    await pumpStartedApp(tester);
    await tester.tap(find.text('Math'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Logic game'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('Logic game'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logic game'));
    await tester.pumpAndSettle();

    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('opens the clipped shopping game stage', (tester) async {
    await pumpStartedApp(tester);
    await tester.tap(find.text('Math'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Shopping game'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('Shopping game'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shopping game'));
    await tester.pumpAndSettle();

    expect(find.text('Shopping game'), findsOneWidget);
    expect(find.byKey(const ValueKey('shopping-game-stage')), findsOneWidget);
    expect(find.byType(ClipRect), findsWidgets);
  });

  testWidgets('system back follows the same math navigation hierarchy', (
    tester,
  ) async {
    await pumpStartedApp(tester);

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
