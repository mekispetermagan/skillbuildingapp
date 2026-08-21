import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/controllers/letter_catching_controller.dart';
import 'package:skillbuilding_game/models/letter_catching_config.dart';
import 'package:skillbuilding_game/models/letter_catching_word.dart';
import 'package:skillbuilding_game/models/letter_catching_world.dart';
import 'package:skillbuilding_game/models/letter_catching_state.dart';

const _config = LetterCatchingConfig(
  fallingSpeed: 0,
  spawnIntervalSeconds: 1000,
  fallingLetterSize: 42,
  paddleWidth: 90,
  paddleHeight: 20,
  paddleBottomPadding: 18,
  poolSize: 10,
  startingLives: 5,
  winningScore: 10,
  maximumUpdateStep: 0.01,
);

LetterCatchingController _controller({
  List<LetterCatchingWord> words = const [
    LetterCatchingWord(id: 1, word: 'LION'),
  ],
  LetterCatchingConfig config = _config,
}) {
  final controller = LetterCatchingController(
    words: words,
    config: config,
    random: Random(3),
  );
  controller
    ..resize(400, 700)
    ..start();
  return controller;
}

void _catch(LetterCatchingController controller, String letter, int id) {
  final world = controller.world;
  world.fallingLetters.add(
    FallingLetter(
      id: id,
      letter: letter,
      x: world.paddleX + 1,
      y: world.paddleY,
    ),
  );
  controller.tick(0.001);
}

void _solveCurrentWord(LetterCatchingController controller, int firstId) {
  final letters = controller.world.currentWord.letterTokens;
  for (final (index, letter) in letters.indexed) {
    _catch(controller, letter, firstId + index);
  }
}

void main() {
  test('builds a ten-entry pool containing every target occurrence', () {
    final controller = _controller(
      words: const [LetterCatchingWord(id: 1, word: 'SHEEP')],
    );
    final pool = controller.world.sourcePool;

    expect(pool, hasLength(10));
    expect(pool.where((letter) => letter == 'E'), hasLength(2));
    for (final letter in 'SHEEP'.split('')) {
      expect(pool, contains(letter));
    }
  });

  test('matches repeated letters one occurrence at a time', () {
    final controller = _controller(
      words: const [LetterCatchingWord(id: 1, word: 'SHEEP')],
    );

    _catch(controller, 'E', 1);
    expect(controller.world.matchedLetters, [false, false, true, false, false]);
    expect(controller.world.score, 0);

    _catch(controller, 'E', 2);
    expect(controller.world.matchedLetters, [false, false, true, true, false]);
    expect(controller.world.score, 0);
  });

  test('supports long words and bracketed Hungarian digraphs', () {
    final longWordController = _controller(
      words: const [LetterCatchingWord(id: 1, word: 'CHIMPANZEE')],
    );
    expect(longWordController.world.sourcePool, hasLength(10));

    final hungarianController = _controller(
      words: const [LetterCatchingWord(id: 1, word: '[NY]ÚL')],
    );
    expect(hungarianController.world.currentWord.letterTokens, [
      'NY',
      'Ú',
      'L',
    ]);
    expect(hungarianController.world.sourcePool, contains('NY'));

    _solveCurrentWord(hungarianController, 20);
    expect(hungarianController.world.score, 1);
  });

  test('wrong catches remove a life without changing score', () {
    final controller = _controller();

    _catch(controller, 'Z', 1);

    expect(controller.world.lives, 4);
    expect(controller.world.score, 0);
    expect(controller.world.fallingLetters, isEmpty);
  });

  test('completing a word adds one point and starts another word', () {
    final controller = _controller();

    _solveCurrentWord(controller, 10);

    expect(controller.world.score, 1);
    expect(controller.world.matchedLetters, everyElement(isFalse));
    expect(controller.world.fallingLetters, isEmpty);
  });

  test('ends on the winning score and restart resets progress', () {
    const quickWinConfig = LetterCatchingConfig(
      fallingSpeed: 0,
      spawnIntervalSeconds: 1000,
      fallingLetterSize: 42,
      paddleWidth: 90,
      paddleHeight: 20,
      paddleBottomPadding: 18,
      poolSize: 10,
      startingLives: 5,
      winningScore: 2,
      maximumUpdateStep: 0.01,
    );
    final controller = _controller(config: quickWinConfig);

    _solveCurrentWord(controller, 10);
    _solveCurrentWord(controller, 20);

    expect(controller.state, LetterCatchingState.won);
    expect(controller.world.score, 2);

    controller.start();
    expect(controller.state, LetterCatchingState.playing);
    expect(controller.world.score, 0);
    expect(controller.world.lives, 5);
  });

  test('ends when all lives are lost', () {
    const quickLossConfig = LetterCatchingConfig(
      fallingSpeed: 0,
      spawnIntervalSeconds: 1000,
      fallingLetterSize: 42,
      paddleWidth: 90,
      paddleHeight: 20,
      paddleBottomPadding: 18,
      poolSize: 10,
      startingLives: 2,
      winningScore: 10,
      maximumUpdateStep: 0.01,
    );
    final controller = _controller(config: quickLossConfig);

    _catch(controller, 'Z', 1);
    _catch(controller, 'Z', 2);

    expect(controller.world.lives, 0);
    expect(controller.state, LetterCatchingState.lost);
  });

  test('keeps the paddle inside the game boundaries', () {
    final controller = _controller();

    controller.movePaddleBy(-1000);
    expect(controller.world.paddleX, 0);
    controller.movePaddleBy(1000);
    expect(controller.world.paddleX, 310);
  });
}
