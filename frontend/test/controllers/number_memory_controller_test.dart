import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/controllers/number_memory_controller.dart';
import 'package:skillbuilding_game/models/number_memory.dart';

void main() {
  test('builds nine distinct numeral-quantity pairs in the lower range', () {
    final controller = NumberMemoryController(random: Random(3));

    expect(controller.cards, hasLength(18));
    expect(
      controller.cards.where(
        (card) => card.kind == NumberMemoryCardKind.numeral,
      ),
      hasLength(9),
    );
    expect(
      controller.cards.where(
        (card) => card.kind == NumberMemoryCardKind.quantity,
      ),
      hasLength(9),
    );
    expect(controller.cards.map((card) => card.pairId).toSet(), hasLength(9));
    for (final card in controller.cards) {
      expect(card.number, inInclusiveRange(1, 12));
      if (card.kind == NumberMemoryCardKind.quantity) {
        expect(card.gridSize, 4);
        expect(card.positions, hasLength(card.number));
        expect(card.positions.toSet(), hasLength(card.number));
        expect(card.positions, everyElement(inInclusiveRange(0, 15)));
      }
    }
    controller.dispose();
  });

  test('upper range uses unique cells in a five-by-five grid', () {
    final controller = NumberMemoryController(random: Random(3));
    controller.setRange(NumberMemoryRange.oneToTwentyFour);

    expect(controller.cards.map((card) => card.pairId).toSet(), hasLength(9));
    for (final card in controller.cards.where(
      (card) => card.kind == NumberMemoryCardKind.quantity,
    )) {
      expect(card.number, inInclusiveRange(1, 24));
      expect(card.gridSize, 5);
      expect(card.positions.toSet(), hasLength(card.number));
      expect(card.positions, everyElement(inInclusiveRange(0, 24)));
    }
    controller.dispose();
  });

  test('hides a mismatch and removes a matching pair', () async {
    final controller = NumberMemoryController(
      random: Random(3),
      revealDuration: Duration.zero,
    );
    final first = controller.cards.first;
    final mismatch = controller.cards.firstWhere(
      (card) => card.pairId != first.pairId,
    );

    await controller.select(first.cardId);
    await controller.select(mismatch.cardId);
    expect(controller.cards.where((card) => card.isFaceUp), isEmpty);
    expect(controller.pairAttempts, 1);
    expect(controller.mismatches, 1);

    final pair = controller.cards.where((card) => card.pairId == first.pairId);
    for (final card in pair) {
      await controller.select(card.cardId);
    }
    expect(
      controller.cards.where((card) => card.pairId == first.pairId),
      everyElement(predicate<NumberMemoryCardData>((card) => card.isMatched)),
    );
    controller.dispose();
  });

  test('range changes create a fresh board and reset metrics', () async {
    final controller = NumberMemoryController(
      random: Random(3),
      revealDuration: Duration.zero,
    );
    final first = controller.cards.first;
    final mismatch = controller.cards.firstWhere(
      (card) => card.pairId != first.pairId,
    );
    await controller.select(first.cardId);
    await controller.select(mismatch.cardId);

    controller.setRange(NumberMemoryRange.oneToTwentyFour);

    expect(controller.range, NumberMemoryRange.oneToTwentyFour);
    expect(controller.pairAttempts, 0);
    expect(controller.mismatches, 0);
    expect(controller.cards.where((card) => card.isFaceUp), isEmpty);
    controller.dispose();
  });

  test('matching all nine pairs completes the board', () async {
    final controller = NumberMemoryController(
      random: Random(3),
      revealDuration: Duration.zero,
    );
    for (final pairId in controller.cards.map((card) => card.pairId).toSet()) {
      final pair = controller.cards.where((card) => card.pairId == pairId);
      for (final card in pair) {
        await controller.select(card.cardId);
      }
    }

    expect(controller.isComplete, isTrue);
    expect(controller.pairAttempts, 9);
    expect(controller.mismatches, 0);
    controller.dispose();
  });
}
