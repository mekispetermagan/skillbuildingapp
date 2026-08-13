import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/controllers/missing_letters_controller.dart';
import 'package:literacy_game/models/missing_letters_state.dart';
import 'package:literacy_game/models/missing_letters_word.dart';

MissingLettersController _controller({
  List<MissingLettersWord> words = const [
    MissingLettersWord(id: 1, word: 'GORILLA'),
  ],
}) => MissingLettersController(words: words, random: Random(7));

void main() {
  test(
    'generates exactly two blanks and a uniquely usable seven-card pool',
    () {
      final controller = _controller();
      final missing = controller.slots.where((slot) => slot.isMissing).toList();

      expect(missing, hasLength(2));
      expect(controller.pool, hasLength(7));
      expect(controller.pool.map((tile) => tile.id).toSet(), hasLength(7));

      for (final letter in missing.map((slot) => slot.letter).toSet()) {
        final requiredCount = missing
            .where((slot) => slot.letter == letter)
            .length;
        final poolCount = controller.pool
            .where((tile) => tile.letter == letter)
            .length;
        expect(poolCount, requiredCount);
      }
      controller.dispose();
    },
  );

  test('ignores an incorrect drop without consuming its card', () {
    final controller = _controller();
    final target = controller.slots.firstWhere((slot) => slot.isMissing);
    final wrongTile = controller.pool.firstWhere(
      (tile) => tile.letter != target.letter,
    );
    final originalPool = controller.pool;

    controller.drop(targetId: target.id, tileId: wrongTile.id);

    expect(
      controller.slots.singleWhere((slot) => slot.id == target.id).isFilled,
      isFalse,
    );
    expect(controller.pool, originalPool);
    expect(controller.state, MissingLettersState.solving);
    controller.dispose();
  });

  test('tap selection toggles and tap placement clears it only on success', () {
    final controller = _controller();
    final target = controller.slots.firstWhere((slot) => slot.isMissing);
    final wrong = controller.pool.firstWhere(
      (tile) => tile.letter != target.letter,
    );
    final correct = controller.pool.firstWhere(
      (tile) => tile.letter == target.letter,
    );

    controller.selectTile(wrong.id);
    expect(controller.selectedTileId, wrong.id);
    controller.placeSelected(target.id);
    expect(controller.selectedTileId, wrong.id);

    controller.selectTile(wrong.id);
    expect(controller.selectedTileId, isNull);
    controller.selectTile(correct.id);
    controller.placeSelected(target.id);
    expect(controller.selectedTileId, isNull);
    expect(
      controller.slots.singleWhere((slot) => slot.id == target.id).isFilled,
      isTrue,
    );
  });

  test('consumes correct cards and enables Next after both drops', () {
    final controller = _controller();
    final targets = controller.slots.where((slot) => slot.isMissing).toList();

    for (final target in targets) {
      final tile = controller.pool.firstWhere(
        (item) => item.letter == target.letter,
      );
      expect(controller.canDrop(targetId: target.id, tileId: tile.id), isTrue);
      controller.drop(targetId: target.id, tileId: tile.id);
    }

    expect(controller.pool, hasLength(5));
    expect(controller.state, MissingLettersState.solved);
    expect(controller.canContinue, isTrue);
    expect(controller.score, 1);

    controller.next();
    expect(controller.state, MissingLettersState.solving);
    expect(controller.score, 1);
    expect(controller.slots.where((slot) => slot.isMissing), hasLength(2));
    expect(controller.pool, hasLength(7));
    controller.dispose();
  });

  test('starting a new session resets the score', () {
    final controller = _controller();
    for (final target
        in controller.slots.where((slot) => slot.isMissing).toList()) {
      final tile = controller.pool.firstWhere(
        (item) => item.letter == target.letter,
      );
      controller.drop(targetId: target.id, tileId: tile.id);
    }
    expect(controller.score, 1);

    controller.start();

    expect(controller.score, 0);
    expect(controller.state, MissingLettersState.solving);
    controller.dispose();
  });

  test('uses every word before starting the next deck', () {
    final controller = _controller(
      words: const [
        MissingLettersWord(id: 1, word: 'LION'),
        MissingLettersWord(id: 2, word: 'ZEBRA'),
        MissingLettersWord(id: 3, word: 'CRANE'),
      ],
    );
    final seen = <String>{};

    for (var exercise = 0; exercise < 3; exercise++) {
      seen.add(controller.slots.map((slot) => slot.letter).join());
      for (final target
          in controller.slots.where((slot) => slot.isMissing).toList()) {
        final tile = controller.pool.firstWhere(
          (item) => item.letter == target.letter,
        );
        controller.drop(targetId: target.id, tileId: tile.id);
      }
      controller.next();
    }

    expect(seen, {'LION', 'ZEBRA', 'CRANE'});
    controller.dispose();
  });
}
