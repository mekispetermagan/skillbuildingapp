import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/controllers/letter_shooting_controller.dart';
import 'package:literacy_game/models/letter_shooting_config.dart';
import 'package:literacy_game/models/letter_shooting_word.dart';
import 'package:literacy_game/models/letter_shooting_world.dart';
import 'package:literacy_game/models/view_data.dart';

const _word = LetterShootingWord(id: 1, word: 'DAD');

const _fastSpawnConfig = LetterShootingConfig(
  projectileSpeed: 600,
  targetSpeed: 50,
  spawnIntervalSeconds: 1,
  projectileSize: 30,
  sourceLetterSize: 38,
  sourceLetterGap: 6,
  sourceLetterColumns: 5,
  targetWidth: 104,
  targetHeight: 50,
  targetLaneGap: 12,
  targetTopPadding: 16,
  cannonWidth: 42,
  cannonHeight: 82,
  cannonBottomClearance: 12,
  maximumUpdateStep: 0.1,
  winningScore: 10,
);

LetterShootingController _controller() {
  final controller = LetterShootingController(words: const [_word]);
  controller
    ..resize(400, 700)
    ..start();
  return controller;
}

void main() {
  test('loads a reusable source letter and fires from the cannon muzzle', () {
    final controller = _controller();
    final source = controller.world.sourceLetters.singleWhere(
      (item) => item.letter == 'A',
    );
    controller.tap(
      GamePoint(
        source.bounds.left + source.bounds.width / 2,
        source.bounds.top + source.bounds.height / 2,
      ),
    );
    expect(controller.world.loadedLetter, 'A');

    final pivot = controller.world.cannonPivot;
    expect(controller.beginAim(GamePoint(pivot.x, pivot.y - 100)), isTrue);
    expect(controller.releaseAim(), isTrue);

    final projectile = controller.world.projectiles.single;
    expect(projectile.letter, 'A');
    expect(projectile.x, closeTo(pivot.x, 0.001));
    expect(
      projectile.y,
      closeTo(pivot.y - controller.world.config.cannonHeight, 0.001),
    );
    expect(controller.world.loadedLetter, isNull);
  });

  test('an unloaded cannon aims but does not fire', () {
    final controller = _controller();
    final pivot = controller.world.cannonPivot;

    expect(controller.beginAim(GamePoint(pivot.x + 50, pivot.y - 100)), isTrue);
    expect(controller.releaseAim(), isFalse);
    expect(controller.world.projectiles, isEmpty);
    expect(controller.world.cannonAngle, greaterThan(0));
  });

  test('correct collision solves the target and increases score', () {
    final controller = _controller();
    final world = controller.world;
    world.targets.add(
      LetterTarget(
        entityId: 20,
        word: _word,
        missingIndex: 1,
        x: 100,
        y: 100,
        direction: 1,
      ),
    );
    world.projectiles.add(
      LetterProjectile(
        entityId: 21,
        letter: 'A',
        x: 120,
        y: 120,
        velocityX: 0,
        velocityY: 0,
      ),
    );

    controller.tick(0.001);

    expect(world.targets.single.isSolved, isTrue);
    expect(world.projectiles, isEmpty);
    expect(world.score, 1);
  });

  test('incorrect collision removes both entities without changing score', () {
    final controller = _controller();
    final world = controller.world;
    world.targets.add(
      LetterTarget(
        entityId: 20,
        word: _word,
        missingIndex: 1,
        x: 100,
        y: 100,
        direction: 1,
      ),
    );
    world.projectiles.add(
      LetterProjectile(
        entityId: 21,
        letter: 'E',
        x: 120,
        y: 120,
        velocityX: 0,
        velocityY: 0,
      ),
    );

    controller.tick(0.001);

    expect(world.targets, isEmpty);
    expect(world.projectiles, isEmpty);
    expect(world.score, 0);
  });

  test('spawns moving targets and removes projectiles at an edge', () {
    final world = LetterShootingWorld(
      words: const [_word],
      config: _fastSpawnConfig,
      random: Random(2),
    )..resize(400, 700);
    world.reset();
    world.projectiles.add(
      LetterProjectile(
        entityId: 40,
        letter: 'A',
        x: 200,
        y: 5,
        velocityX: 0,
        velocityY: -600,
      ),
    );

    for (var step = 0; step < 4; step++) {
      world.update(0.25);
    }

    expect(world.targets, isNotEmpty);
    expect(world.projectiles, isEmpty);
  });

  test('offers only vowels and randomizes the missing vowel per target', () {
    const multiVowelWord = LetterShootingWord(id: 2, word: 'AUNT');
    final world = LetterShootingWorld(
      words: const [multiVowelWord],
      config: _fastSpawnConfig,
      random: Random(4),
    )..resize(400, 700);
    world.reset();

    for (var second = 0; second < 20; second++) {
      for (var step = 0; step < 4; step++) {
        world.update(0.25);
      }
    }

    expect(world.sourceLetters.map((source) => source.letter), [
      'A',
      'E',
      'I',
      'O',
      'U',
    ]);
    expect(world.targets.map((target) => target.missingLetter).toSet(), {
      'A',
      'U',
    });
    expect(
      world.targets.every(
        (target) =>
            target.displayWord == '_UNT' || target.displayWord == 'A_NT',
      ),
      isTrue,
    );
  });

  test('ends at ten points and restart resets the game', () {
    final controller = _controller();
    final world = controller.world;

    for (var score = 0; score < 10; score++) {
      world.targets.add(
        LetterTarget(
          entityId: 100 + score * 2,
          word: _word,
          missingIndex: 1,
          x: 100,
          y: 100,
          direction: 1,
        ),
      );
      world.projectiles.add(
        LetterProjectile(
          entityId: 101 + score * 2,
          letter: 'A',
          x: 120,
          y: 120,
          velocityX: 0,
          velocityY: 0,
        ),
      );
      controller.tick(0.001);
    }

    expect(world.score, 10);
    expect(controller.state, LetterShootingState.ended);
    final frozenX = world.targets.first.x;
    controller.tick(1);
    expect(world.targets.first.x, frozenX);

    final source = world.sourceLetters.first;
    controller.tap(GamePoint(source.bounds.left + 1, source.bounds.top + 1));
    expect(world.loadedLetter, isNull);

    controller.start();
    expect(controller.state, LetterShootingState.playing);
    expect(world.score, 0);
    expect(world.targets, isEmpty);
    expect(world.projectiles, isEmpty);
  });
}
