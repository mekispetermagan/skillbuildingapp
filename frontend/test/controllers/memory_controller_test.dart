import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/controllers/memory_controller.dart';
import 'package:skillbuilding_game/models/memory_card_data.dart';
import 'package:skillbuilding_game/models/image_word.dart';

List<ImageWord> _pairs() => [
  for (var id = 1; id <= 12; id++)
    ImageWord(
      id: id,
      word: 'word$id',
      imagePath: 'image$id.png',
      audioPath: 'audio$id.mp3',
    ),
];

void main() {
  test('builds nine shuffled word-image pairs from the available pool', () {
    final controller = MemoryController(pairs: _pairs(), random: Random(3));

    expect(controller.cards, hasLength(18));
    expect(
      controller.cards.where((card) => card.kind == MemoryCardKind.word),
      hasLength(9),
    );
    expect(
      controller.cards.where((card) => card.kind == MemoryCardKind.image),
      hasLength(9),
    );
    for (final pairId in controller.cards.map((card) => card.pairId).toSet()) {
      expect(
        controller.cards.where((card) => card.pairId == pairId),
        hasLength(2),
      );
    }
    controller.dispose();
  });

  test('hides a mismatch and removes a matching pair', () async {
    final controller = MemoryController(
      pairs: _pairs(),
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

    final pair = controller.cards.where((card) => card.pairId == first.pairId);
    for (final card in pair) {
      await controller.select(card.cardId);
    }
    expect(
      controller.cards.where((card) => card.pairId == first.pairId),
      everyElement(predicate<MemoryCardData>((card) => card.isMatched)),
    );
    controller.dispose();
  });

  test('cannot play with fewer than nine pairs', () {
    final controller = MemoryController(
      pairs: _pairs().take(8).toList(),
      random: Random(3),
    );

    expect(controller.canPlay, isFalse);
    expect(controller.cards, isEmpty);
    controller.dispose();
  });

  test('new game invalidates a pending card comparison', () async {
    final controller = MemoryController(
      pairs: _pairs(),
      random: Random(3),
      revealDuration: const Duration(milliseconds: 10),
    );
    final first = controller.cards.first;
    final second = controller.cards.firstWhere(
      (card) => card.pairId != first.pairId,
    );
    await controller.select(first.cardId);
    final comparison = controller.select(second.cardId);

    controller.startNewGame();
    await comparison;

    expect(controller.cards.where((card) => card.isFaceUp), isEmpty);
    expect(controller.canPlay, isTrue);
    controller.dispose();
  });
}
