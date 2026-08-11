import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/controllers/spelling_quiz_controller.dart';
import 'package:literacy_game/models/image_word.dart';
import 'package:literacy_game/models/spelling_quiz_state.dart';

const _animals = [
  ImageWord(id: 1, word: 'baboon', imagePath: 'baboon.png'),
  ImageWord(id: 2, word: 'guinea fowl', imagePath: 'guinea_fowl.png'),
  ImageWord(id: 3, word: 'lion', imagePath: 'lion.png'),
  ImageWord(id: 4, word: 'zebra', imagePath: 'zebra.png'),
];

void main() {
  test('creates unique same-class one-letter distractors', () {
    final controller = SpellingQuizController(
      animals: _animals,
      random: Random(7),
      feedbackDuration: Duration.zero,
    );
    final realWords = _animals.map((animal) => animal.uppercaseWord).toSet();

    for (var questionNumber = 0; questionNumber < 20; questionNumber++) {
      final question = controller.question;
      expect(question.options, hasLength(4));
      expect(question.options.toSet(), hasLength(4));
      expect(question.solution, question.animal.uppercaseWord);

      for (final option in question.options.where(
        (option) => option != question.solution,
      )) {
        expect(realWords, isNot(contains(option)));
        final differences = <int>[
          for (var index = 0; index < option.length; index++)
            if (option[index] != question.solution[index]) index,
        ];
        expect(differences, hasLength(1));
        final changedIndex = differences.single;
        expect(changedIndex, greaterThan(0));
        expect(question.solution[changedIndex - 1], isNot(' '));
        expect(option[changedIndex], isNot(' '));
        expect(
          _isVowel(option[changedIndex]),
          _isVowel(question.solution[changedIndex]),
        );
      }

      controller.start();
    }
    controller.dispose();
  });

  test('protects the first letter of every word', () {
    final controller = SpellingQuizController(
      animals: const [
        ImageWord(id: 1, word: 'guinea fowl', imagePath: 'guinea_fowl.png'),
      ],
      random: Random(1),
    );

    for (final option in controller.question.options) {
      expect(option[0], 'G');
      expect(option[7], 'F');
    }
    controller.dispose();
  });

  test('wrong answers do not score and correct answers win at ten', () async {
    final controller = SpellingQuizController(
      animals: _animals,
      random: Random(3),
      feedbackDuration: Duration.zero,
    );

    final wrongIndex = controller.question.correctIndex == 0 ? 1 : 0;
    await controller.submit(wrongIndex);
    expect(controller.score, 0);
    expect(controller.state, SpellingQuizState.guessing);

    for (var score = 1; score <= spellingQuizWinningScore; score++) {
      await controller.submit(controller.question.correctIndex);
      expect(controller.score, score);
    }
    expect(controller.state, SpellingQuizState.won);

    controller.start();
    expect(controller.score, 0);
    expect(controller.state, SpellingQuizState.guessing);
    controller.dispose();
  });
}

bool _isVowel(String letter) => 'AEIOU'.contains(letter);
