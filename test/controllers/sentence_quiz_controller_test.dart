import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/controllers/sentence_quiz_controller.dart';

SentenceQuizController _controller() =>
    SentenceQuizController(random: Random(8), feedbackDuration: Duration.zero);

void main() {
  test('offers one solution and three distractors false for both layers', () {
    final controller = _controller();

    for (var exercise = 0; exercise < 50; exercise++) {
      final question = controller.question;
      final visibleSentences = {question.visibleShirt, question.visibleJeans};

      expect(question.options, hasLength(4));
      expect(question.options.toSet(), hasLength(4));
      expect(visibleSentences, contains(question.solution));
      for (final (index, option) in question.options.indexed) {
        if (index != question.correctIndex) {
          expect(visibleSentences, isNot(contains(option)));
        }
      }
      controller.start();
    }
  });

  test(
    'wrong guess highlights wrong and correct choices without scoring',
    () async {
      final controller = SentenceQuizController(
        random: Random(2),
        feedbackDuration: const Duration(milliseconds: 1),
      );
      final wrongIndex = controller.question.correctIndex == 0 ? 1 : 0;
      final submission = controller.submit(wrongIndex);

      expect(controller.state, SentenceQuizState.feedback);
      expect(controller.wrongHighlightIndex, wrongIndex);
      expect(
        controller.correctHighlightIndex,
        controller.question.correctIndex,
      );
      expect(controller.score, 0);

      await submission;
      expect(controller.state, SentenceQuizState.guessing);
      expect(controller.wrongHighlightIndex, isNull);
      expect(controller.correctHighlightIndex, isNull);
    },
  );

  test('correct guesses add rewards and the tenth ends the game', () async {
    final controller = _controller();

    for (var score = 1; score <= sentenceQuizWinningScore; score++) {
      await controller.submit(controller.question.correctIndex);
      expect(controller.score, score);
    }

    expect(controller.state, SentenceQuizState.won);
    expect(controller.canSubmit, isFalse);

    controller.start();
    expect(controller.state, SentenceQuizState.guessing);
    expect(controller.score, 0);
  });

  test('ignores another answer while feedback is showing', () async {
    final controller = SentenceQuizController(
      random: Random(5),
      feedbackDuration: const Duration(milliseconds: 1),
    );
    final correctIndex = controller.question.correctIndex;
    final submission = controller.submit(correctIndex);

    await controller.submit(correctIndex);
    expect(controller.score, 1);

    await submission;
    expect(controller.score, 1);
  });
}
