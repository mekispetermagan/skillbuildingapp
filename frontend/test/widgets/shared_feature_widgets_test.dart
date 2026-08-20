import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/l10n/app_localizations.dart';
import 'package:skillbuilding_game/models/feature_load_error.dart';
import 'package:skillbuilding_game/models/answer_feedback.dart';
import 'package:skillbuilding_game/widgets/feature_load_state.dart';
import 'package:skillbuilding_game/widgets/game_end_overlay.dart';
import 'package:skillbuilding_game/widgets/quiz_option_button.dart';
import 'package:skillbuilding_game/widgets/reward_gem_row.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('feature load state prioritizes loading and errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const FeatureLoadState(
          isLoading: true,
          loadError: FeatureLoadError.crossword,
          child: Text('Content'),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Not shown yet'), findsNothing);

    await tester.pumpWidget(
      app(
        const FeatureLoadState(
          isLoading: false,
          loadError: FeatureLoadError.crossword,
          child: Text('Content'),
        ),
      ),
    );
    expect(find.text('Could not load the crossword activity.'), findsOneWidget);
    expect(find.text('Content'), findsNothing);
  });

  testWidgets('game end overlay exposes its result and restart action', (
    tester,
  ) async {
    var restarted = false;
    await tester.pumpWidget(
      app(
        GameEndOverlay(
          message: 'Congratulations!',
          onRestart: () => restarted = true,
        ),
      ),
    );

    expect(find.text('Congratulations!'), findsOneWidget);
    await tester.tap(find.text('Play again'));
    expect(restarted, isTrue);
  });

  testWidgets('quiz option button renders feedback and submits', (
    tester,
  ) async {
    var submitted = false;
    await tester.pumpWidget(
      app(
        QuizOptionButton(
          label: 'Mary wears a blue shirt.',
          feedback: AnswerFeedback.correct,
          onPressed: () => submitted = true,
        ),
      ),
    );

    expect(find.text('Mary wears a blue shirt.'), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    expect(submitted, isTrue);
  });

  testWidgets('reward row keeps its height with no rewards', (tester) async {
    await tester.pumpWidget(app(const RewardGemRow(count: 0)));

    expect(tester.getSize(find.byType(RewardGemRow)).height, 46);
  });

  testWidgets('ten reward gems scale to a narrow game width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(240, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app(const RewardGemRow(count: 10)));

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(RewardGemRow)).width, 240);
  });
}
