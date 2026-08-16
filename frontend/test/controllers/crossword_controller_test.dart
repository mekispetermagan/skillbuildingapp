import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/controllers/crossword_controller.dart';
import 'package:literacy_game/controllers/crossword_generator.dart';
import 'package:literacy_game/models/crossword_config.dart';
import 'package:literacy_game/models/crossword_entry.dart';
import 'package:literacy_game/models/crossword_state.dart';

const _entries = [
  CrosswordEntry(word: 'CAT', clue: 'A pet that says meow.'),
  CrosswordEntry(word: 'CAR', clue: 'A small road vehicle.'),
  CrosswordEntry(word: 'BAR', clue: 'A long solid piece.'),
  CrosswordEntry(word: 'BAT', clue: 'An animal that flies at night.'),
  CrosswordEntry(word: 'RAT', clue: 'An animal like a large mouse.'),
  CrosswordEntry(word: 'TAR', clue: 'A dark road material.'),
];

const _testConfig = CrosswordConfig(
  cellSize: 48,
  alphabetCellSize: 48,
  maximumGridSize: 6,
  revealFraction: 0.5,
  winningScore: 3,
  generationAttempts: 100,
  completedCrosswordDuration: Duration.zero,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the temporary vocabulary asset can generate a puzzle', () async {
    final encoded = await rootBundle.loadString(
      'assets/data/crossword_words.json',
    );
    final data = jsonDecode(encoded) as List<dynamic>;
    final entries = [
      for (final item in data)
        CrosswordEntry.fromJson(item as Map<String, dynamic>),
    ];

    expect(entries.length, greaterThanOrEqualTo(40));
    expect(entries.every((entry) => entry.word.length <= 6), isTrue);
    final puzzle = CrosswordGenerator(
      entries: entries,
      config: _testConfig,
      random: Random(11),
    ).generate();
    expect(puzzle.cells, isNotEmpty);
  });

  test('generates a bounded puzzle with numbered clues and half revealed', () {
    final generator = CrosswordGenerator(
      entries: _entries,
      config: _testConfig,
      random: Random(4),
    );

    final puzzle = generator.generate();

    expect(puzzle.columnCount, lessThanOrEqualTo(6));
    expect(puzzle.rowCount, lessThanOrEqualTo(6));
    expect(puzzle.clues, hasLength(puzzle.mainWord.length));
    expect(
      puzzle.clues.map((clue) => clue.entry.word).toSet(),
      hasLength(puzzle.clues.length),
    );
    expect(
      puzzle.cells.where((cell) => cell.isRevealed),
      hasLength((puzzle.cells.length * 0.5).round()),
    );
    expect(
      puzzle.cells.where((cell) => cell.clueNumber != null),
      hasLength(puzzle.clues.length),
    );
    expect(puzzle.alphabet.toSet(), {
      for (final cell in puzzle.cells)
        if (!cell.isRevealed) cell.letter,
    });
  });

  test(
    'tap selection toggles and a wrong placement keeps it selected',
    () async {
      final controller = CrosswordController(
        entries: _entries,
        config: _testConfig,
        random: Random(7),
      );
      final hidden = controller.puzzle.cells
          .where((cell) => !cell.isRevealed)
          .toList();
      final target = hidden.firstWhere(
        (cell) => hidden.any((other) => other.letter != cell.letter),
      );
      final wrongLetter = hidden
          .firstWhere((cell) => cell.letter != target.letter)
          .letter;

      controller.selectLetter(wrongLetter);
      expect(controller.selectedLetter, wrongLetter);
      await controller.placeSelected(target.id);
      expect(controller.selectedLetter, wrongLetter);
      expect(
        controller.puzzle.cells
            .firstWhere((cell) => cell.id == target.id)
            .isRevealed,
        isFalse,
      );
      controller.selectLetter(wrongLetter);
      expect(controller.selectedLetter, isNull);
      controller.dispose();
    },
  );

  test('tap and drag placement share validation and reveal behavior', () async {
    final controller = CrosswordController(
      entries: _entries,
      config: _testConfig,
      random: Random(2),
    );
    final first = controller.puzzle.cells.firstWhere(
      (cell) => !cell.isRevealed,
    );
    controller.selectLetter(first.letter);
    expect(controller.canPlace(cellId: first.id, letter: first.letter), isTrue);
    await controller.placeSelected(first.id);
    expect(
      controller.puzzle.cells
          .firstWhere((cell) => cell.id == first.id)
          .isRevealed,
      isTrue,
    );
    expect(controller.selectedLetter, isNull);

    final second = controller.puzzle.cells.firstWhere(
      (cell) => !cell.isRevealed,
    );
    await controller.place(cellId: second.id, letter: second.letter);
    expect(
      controller.puzzle.cells
          .firstWhere((cell) => cell.id == second.id)
          .isRevealed,
      isTrue,
    );
    controller.dispose();
  });

  test('awards one gem per crossword and wins after three', () async {
    final controller = CrosswordController(
      entries: _entries,
      config: _testConfig,
      random: Random(5),
    );

    for (var expectedScore = 1; expectedScore <= 3; expectedScore++) {
      final hiddenCells = controller.puzzle.cells
          .where((cell) => !cell.isRevealed)
          .toList();
      for (final cell in hiddenCells) {
        await controller.place(cellId: cell.id, letter: cell.letter);
      }
      expect(controller.score, expectedScore);
    }
    expect(controller.state, CrosswordState.won);

    controller.start();
    expect(controller.score, 0);
    expect(controller.state, CrosswordState.playing);
    controller.dispose();
  });
}
