import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/controllers/conveyor_controller.dart';
import 'package:literacy_game/models/conveyor_config.dart';
import 'package:literacy_game/models/conveyor_word.dart';
import 'package:literacy_game/models/conveyor_world.dart';

const _config = ConveyorConfig(
  leftBeltWidth: 290,
  rightBeltWidth: 70,
  beltGap: 14,
  outerPadding: 10,
  shelfHeight: 126,
  shelfGap: 16,
  letterSize: 54,
  letterGap: 18,
  leftBeltSpeed: 34,
  rightBeltSpeed: 82,
  startingLives: 5,
  winningScore: 10,
  maximumUpdateStep: 0.01,
);

const _words = [
  ConveyorWord(id: 1, word: 'SHEEP', imagePath: 'sheep.png'),
  ConveyorWord(id: 2, word: 'GOAT', imagePath: 'goat.png'),
];

ConveyorController _controller({ConveyorConfig config = _config}) {
  final controller = ConveyorController(
    words: _words,
    config: config,
    random: Random(4),
  );
  controller
    ..resize(420, 650)
    ..start();
  return controller;
}

ConveyorDropResult _dropMatching(
  ConveyorController controller,
  ConveyorShelf shelf,
) {
  final missingIndex = shelf.missingIndices.firstWhere(
    (index) => !shelf.recoveredIndices.contains(index),
  );
  final letter = controller.world.letters.first;
  letter.letter = shelf.word.word[missingIndex];
  final result = controller.world.drop(letterId: letter.id, shelfId: shelf.id);
  controller.tick(0);
  return result;
}

void main() {
  test('creates shelves with exactly two hidden letters', () {
    final controller = _controller();

    expect(controller.world.shelves, isNotEmpty);
    for (final shelf in controller.world.shelves) {
      expect(shelf.missingIndices, hasLength(2));
      expect(shelf.missingIndices.toSet(), hasLength(2));
    }
  });

  test('rewards a completed word rather than each recovered gap', () {
    final controller = _controller();
    final shelf = controller.world.shelves.first;

    expect(_dropMatching(controller, shelf), ConveyorDropResult.matched);
    expect(controller.world.score, 0);
    expect(_dropMatching(controller, shelf), ConveyorDropResult.completed);
    expect(controller.world.score, 1);
  });

  test('identical missing letters recover leftmost first', () {
    final controller = _controller();
    final sheepShelf = controller.world.shelves.firstWhere(
      (shelf) => shelf.word.word == 'SHEEP',
    );
    sheepShelf
      ..missingIndices.clear()
      ..missingIndices.addAll([2, 3]);
    final letter = controller.world.letters.first..letter = 'E';

    controller.world.drop(letterId: letter.id, shelfId: sheepShelf.id);

    expect(sheepShelf.recoveredIndices, {2});
  });

  test('wrong placement costs one life and no score', () {
    final controller = _controller();
    final shelf = controller.world.shelves.first;
    final letter = controller.world.letters.first..letter = 'Z';

    controller.drop(letterId: letter.id, shelfId: shelf.id);

    expect(controller.world.lives, 4);
    expect(controller.world.score, 0);
  });

  test('left belt moves down and right belt moves up', () {
    final controller = _controller();
    final shelf = controller.world.shelves[1];
    final letter = controller.world.letters.first;
    final shelfY = shelf.y;
    final letterY = letter.y;

    controller.tick(0.1);

    expect(shelf.y, greaterThan(shelfY));
    expect(letter.y, lessThan(letterY));
  });

  test('ends after ten completed words and restart resets progress', () {
    const quickConfig = ConveyorConfig(
      leftBeltWidth: 290,
      rightBeltWidth: 70,
      beltGap: 14,
      outerPadding: 10,
      shelfHeight: 126,
      shelfGap: 16,
      letterSize: 54,
      letterGap: 18,
      leftBeltSpeed: 0,
      rightBeltSpeed: 0,
      startingLives: 5,
      winningScore: 2,
      maximumUpdateStep: 0.01,
    );
    final controller = _controller(config: quickConfig);

    for (final shelf in controller.world.shelves.take(2)) {
      _dropMatching(controller, shelf);
      _dropMatching(controller, shelf);
    }

    expect(controller.state, ConveyorState.won);
    expect(controller.world.score, 2);

    controller.start();
    expect(controller.state, ConveyorState.playing);
    expect(controller.world.score, 0);
    expect(controller.world.lives, 5);
  });

  test('ends when all lives are lost', () {
    const quickConfig = ConveyorConfig(
      leftBeltWidth: 290,
      rightBeltWidth: 70,
      beltGap: 14,
      outerPadding: 10,
      shelfHeight: 126,
      shelfGap: 16,
      letterSize: 54,
      letterGap: 18,
      leftBeltSpeed: 0,
      rightBeltSpeed: 0,
      startingLives: 1,
      winningScore: 10,
      maximumUpdateStep: 0.01,
    );
    final controller = _controller(config: quickConfig);
    final shelf = controller.world.shelves.first;
    final letter = controller.world.letters.first..letter = 'Z';

    controller.drop(letterId: letter.id, shelfId: shelf.id);

    expect(controller.state, ConveyorState.lost);
    expect(controller.world.lives, 0);
  });
}
