import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/controllers/sentence_composer_controller.dart';
import 'package:skillbuilding_game/models/outfit_sentence.dart';
import 'package:skillbuilding_game/models/sentence_composer_state.dart';
import 'package:skillbuilding_game/models/sentence_content.dart';

SentenceComposerController _controller() => SentenceComposerController(
  random: Random(12),
  feedbackDuration: Duration.zero,
);

void _selectCorrect(
  SentenceComposerController controller,
  ClothingPiece piece,
) {
  controller
    ..selectPerson(controller.outfit.person)
    ..selectColor(controller.outfit.colorFor(piece))
    ..selectPiece(piece);
}

void main() {
  test('derives wears a for shirts and wears for jeans', () {
    final controller = _controller();
    controller
      ..selectPerson(SentencePerson.mary)
      ..selectColor(GarmentColor.blue)
      ..selectPiece(ClothingPiece.shirt);

    expect(controller.composedSentence, 'Mary wears a blue shirt.');

    controller.selectPiece(ClothingPiece.jeans);
    expect(controller.composedSentence, 'Mary wears blue jeans.');
  });

  test('composes the localized Hungarian sentence pattern', () {
    final controller =
        SentenceComposerController(
            content: hungarianSentenceContent,
            random: Random(12),
          )
          ..selectPerson(SentencePerson.sarah)
          ..selectColor(GarmentColor.red)
          ..selectPiece(ClothingPiece.jeans);

    expect(controller.composedSentence, 'Sára piros nadrágban van.');
    expect(controller.content.personName(SentencePerson.mary), 'Márti');
    expect(controller.content.personName(SentencePerson.timothy), 'Tamás');
    controller.dispose();
  });

  test('requires one selection from every selectable sentence part', () {
    final controller = _controller();

    expect(controller.canSubmit, isFalse);
    controller.selectPerson(SentencePerson.sarah);
    controller.selectColor(GarmentColor.red);
    expect(controller.canSubmit, isFalse);
    controller.selectPiece(ClothingPiece.jeans);
    expect(controller.canSubmit, isTrue);
  });

  test('accepts either visible garment with its matching color', () async {
    final shirtController = _controller();
    _selectCorrect(shirtController, ClothingPiece.shirt);
    await shirtController.submit();
    expect(shirtController.score, 1);

    final jeansController = _controller();
    _selectCorrect(jeansController, ClothingPiece.jeans);
    await jeansController.submit();
    expect(jeansController.score, 1);
  });

  test('wrong choices reveal correct person and garment color', () async {
    final controller = SentenceComposerController(
      random: Random(3),
      feedbackDuration: const Duration(milliseconds: 1),
    );
    const piece = ClothingPiece.shirt;
    final wrongPerson = SentencePerson.values.firstWhere(
      (person) => person != controller.outfit.person,
    );
    final wrongColor = GarmentColor.values.firstWhere(
      (color) => color != controller.outfit.colorFor(piece),
    );
    controller
      ..selectPerson(wrongPerson)
      ..selectColor(wrongColor)
      ..selectPiece(piece);

    final submission = controller.submit();

    expect(controller.state, SentenceComposerState.feedback);
    expect(
      controller.personFeedback(wrongPerson),
      ComposerChoiceAssessment.wrong,
    );
    expect(
      controller.personFeedback(controller.outfit.person),
      ComposerChoiceAssessment.correct,
    );
    expect(
      controller.colorFeedback(wrongColor),
      ComposerChoiceAssessment.wrong,
    );
    expect(
      controller.colorFeedback(controller.outfit.shirtColor),
      ComposerChoiceAssessment.correct,
    );
    expect(controller.pieceFeedback(piece), ComposerChoiceAssessment.correct);
    expect(controller.score, 0);

    await submission;
    expect(controller.state, SentenceComposerState.composing);
  });

  test(
    'the tenth correct sentence ends the game and restart resets it',
    () async {
      final controller = _controller();

      for (var score = 1; score <= sentenceComposerWinningScore; score++) {
        _selectCorrect(controller, ClothingPiece.jeans);
        await controller.submit();
        expect(controller.score, score);
      }

      expect(controller.state, SentenceComposerState.won);
      expect(controller.canSubmit, isFalse);

      controller.start();
      expect(controller.state, SentenceComposerState.composing);
      expect(controller.score, 0);
      expect(controller.selectedPerson, isNull);
      expect(controller.selectedColor, isNull);
      expect(controller.selectedPiece, isNull);
    },
  );

  test('restart invalidates feedback from the previous session', () async {
    final controller = SentenceComposerController(
      random: Random(12),
      feedbackDuration: const Duration(milliseconds: 10),
    );
    _selectCorrect(controller, ClothingPiece.shirt);
    final submission = controller.submit();

    controller.start();
    await submission;

    expect(controller.score, 0);
    expect(controller.state, SentenceComposerState.composing);
    expect(controller.selectedPerson, isNull);
  });
}
