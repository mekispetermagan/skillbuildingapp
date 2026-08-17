import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/controllers/even_odd_controller.dart';
import 'package:literacy_game/models/even_odd_config.dart';
import 'package:literacy_game/models/even_odd_world.dart';
import 'package:literacy_game/models/letter_catching_state.dart';

const _config = EvenOddConfig(
  fallingSpeed: 0,
  spawnIntervalSeconds: 1000,
  fallingNumberSize: 42,
  paddleWidth: 90,
  paddleHeight: 20,
  paddleBottomPadding: 18,
  maximumNumber: 30,
  startingLives: 5,
  winningScore: 10,
  maximumUpdateStep: 0.01,
);

EvenOddController _controller({EvenOddConfig config = _config}) {
  final controller = EvenOddController(config: config, random: Random(3));
  controller
    ..resize(400, 700)
    ..start();
  return controller;
}

void _catch(EvenOddController controller, int number, int id) {
  final world = controller.world;
  world.fallingNumbers.add(
    FallingNumber(
      id: id,
      number: number,
      x: world.paddleX + 1,
      y: world.paddleY,
    ),
  );
  controller.tick(0.001);
}

void main() {
  test('starts even and every toggle changes the accepted parity', () {
    final controller = _controller();

    expect(controller.world.parity, NumberParity.even);
    controller.toggleParity();
    expect(controller.world.parity, NumberParity.odd);
    controller.toggleParity();
    expect(controller.world.parity, NumberParity.even);
  });

  test('matching catches reward and mismatching catches cost a life', () {
    final controller = _controller();

    _catch(controller, 8, 1);
    expect(controller.world.score, 1);
    expect(controller.world.lives, 5);

    _catch(controller, 9, 2);
    expect(controller.world.score, 1);
    expect(controller.world.lives, 4);

    controller.toggleParity();
    _catch(controller, 9, 3);
    expect(controller.world.score, 2);
    expect(controller.world.lives, 4);
  });

  test('ends at the winning score and restart resets to even', () {
    final controller = _controller(config: _config.copyWith(winningScore: 2));

    _catch(controller, 2, 1);
    _catch(controller, 30, 2);
    expect(controller.state, LetterCatchingState.won);

    controller.start();
    expect(controller.state, LetterCatchingState.playing);
    expect(controller.world.score, 0);
    expect(controller.world.parity, NumberParity.even);
  });

  test('ends when all lives are lost', () {
    final controller = _controller(config: _config.copyWith(startingLives: 2));

    _catch(controller, 1, 1);
    _catch(controller, 3, 2);
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

extension on EvenOddConfig {
  EvenOddConfig copyWith({int? startingLives, int? winningScore}) =>
      EvenOddConfig(
        fallingSpeed: fallingSpeed,
        spawnIntervalSeconds: spawnIntervalSeconds,
        fallingNumberSize: fallingNumberSize,
        paddleWidth: paddleWidth,
        paddleHeight: paddleHeight,
        paddleBottomPadding: paddleBottomPadding,
        maximumNumber: maximumNumber,
        startingLives: startingLives ?? this.startingLives,
        winningScore: winningScore ?? this.winningScore,
        maximumUpdateStep: maximumUpdateStep,
      );
}
