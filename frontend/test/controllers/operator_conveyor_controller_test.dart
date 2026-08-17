import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/controllers/operator_conveyor_controller.dart';
import 'package:literacy_game/models/conveyor_config.dart';
import 'package:literacy_game/models/conveyor_state.dart';
import 'package:literacy_game/models/operator_conveyor_world.dart';

const _config = ConveyorConfig(
  leftBeltWidth: 290,
  rightBeltWidth: 70,
  beltGap: 14,
  outerPadding: 10,
  shelfHeight: 126,
  shelfGap: 16,
  letterSize: 54,
  letterGap: 18,
  leftBeltSpeed: 15,
  rightBeltSpeed: 30,
  startingLives: 5,
  winningScore: 10,
  maximumUpdateStep: 1 / 120,
);

OperatorConveyorController _controller({ConveyorConfig config = _config}) {
  final controller = OperatorConveyorController(
    config: config,
    random: Random(4),
  );
  controller
    ..resize(420, 650)
    ..start();
  return controller;
}

void main() {
  test('generates whole-number equations with all values at most twenty', () {
    final controller = _controller();
    for (final shelf in controller.world.shelves) {
      final equation = shelf.equation;
      expect(equation.left, inInclusiveRange(1, 20));
      expect(equation.right, inInclusiveRange(1, 20));
      expect(equation.result, inInclusiveRange(1, 20));
      expect(ArithmeticOperator.values.any(equation.accepts), isTrue);
    }
  });

  test('easy right belt alternates three operators without division', () {
    final controller = _controller();
    expect(controller.world.operators.take(6).map((tile) => tile.operator), [
      ArithmeticOperator.add,
      ArithmeticOperator.subtract,
      ArithmeticOperator.multiply,
      ArithmeticOperator.add,
      ArithmeticOperator.subtract,
      ArithmeticOperator.multiply,
    ]);
  });

  test('hard mode adds division, raises ceiling, and preserves progress', () {
    final controller = _controller();
    final shelf = controller.world.shelves.first;
    final tile = controller.world.operators.first
      ..operator = ArithmeticOperator.values.firstWhere(shelf.equation.accepts);
    controller.drop(operatorId: tile.id, shelfId: shelf.id);
    final lives = controller.world.lives;

    controller.setDifficulty(ConveyorDifficulty.hard);

    expect(controller.world.score, 1);
    expect(controller.world.lives, lives);
    expect(controller.world.operators.take(4).map((tile) => tile.operator), [
      ArithmeticOperator.add,
      ArithmeticOperator.subtract,
      ArithmeticOperator.multiply,
      ArithmeticOperator.divide,
    ]);
    for (final generatedShelf in controller.world.shelves) {
      expect(generatedShelf.equation.left, inInclusiveRange(1, 30));
      expect(generatedShelf.equation.right, inInclusiveRange(1, 30));
      expect(generatedShelf.equation.result, inInclusiveRange(1, 30));
    }
  });

  test('equation correctness allows ambiguous operators', () {
    const equation = OperatorEquation(left: 2, right: 2, result: 4);
    expect(equation.accepts(ArithmeticOperator.add), isTrue);
    expect(equation.accepts(ArithmeticOperator.multiply), isTrue);
    expect(equation.accepts(ArithmeticOperator.subtract), isFalse);
  });

  test('wrong equation costs a life and remains incomplete', () {
    final controller = _controller();
    final shelf = controller.world.shelves.first;
    final tile = controller.world.operators.firstWhere(
      (candidate) => !shelf.equation.accepts(candidate.operator),
    );
    controller.drop(operatorId: tile.id, shelfId: shelf.id);
    expect(controller.world.lives, 4);
    expect(controller.world.score, 0);
    expect(shelf.isComplete, isFalse);
  });

  test('valid equation adds a reward and fills the operator', () {
    final controller = _controller();
    final shelf = controller.world.shelves.first;
    final tile = controller.world.operators.first;
    tile.operator = ArithmeticOperator.values.firstWhere(
      shelf.equation.accepts,
    );
    final accepted = tile.operator;
    controller.drop(operatorId: tile.id, shelfId: shelf.id);
    expect(controller.world.score, 1);
    expect(shelf.isComplete, isTrue);
    expect(shelf.placedOperator, accepted);
  });

  test('wide belt moves down slowly and thin belt moves up faster', () {
    final controller = _controller();
    final shelf = controller.world.shelves[1];
    final tile = controller.world.operators.first;
    final shelfY = shelf.y;
    final tileY = tile.y;
    controller.tick(0.1);
    expect(shelf.y - shelfY, closeTo(1.5, 0.001));
    expect(tileY - tile.y, closeTo(3, 0.001));
  });

  test('rejected operator drag returns at its moving belt position', () {
    final controller = _controller();
    final tile = controller.world.operators.first;
    final initialY = tile.y;

    controller.startDragging(tile.id);
    controller.tick(0.1);
    controller.cancelDragging(tile.id);

    expect(tile.y, closeTo(initialY - 3, 0.001));
    expect(tile.isDragging, isFalse);
  });

  test('dragged operator waits to recycle until released', () {
    final controller = _controller();
    final tile = controller.world.operators.first
      ..y = -controller.world.config.letterSize;
    final originalOperator = tile.operator;

    controller.startDragging(tile.id);
    controller.tick(0.1);
    expect(tile.operator, originalOperator);

    controller.cancelDragging(tile.id);
    controller.tick(0.01);
    expect(tile.y, greaterThanOrEqualTo(controller.world.height));
  });

  test('loses when the last life is used', () {
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
      maximumUpdateStep: 1 / 120,
    );
    final controller = _controller(config: quickConfig);
    final shelf = controller.world.shelves.first;
    final tile = controller.world.operators.firstWhere(
      (candidate) => !shelf.equation.accepts(candidate.operator),
    );
    controller.drop(operatorId: tile.id, shelfId: shelf.id);
    expect(controller.state, ConveyorState.lost);
  });
}
