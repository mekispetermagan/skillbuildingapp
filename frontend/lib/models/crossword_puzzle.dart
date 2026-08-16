import 'dart:collection';

import 'crossword_entry.dart';

class CrosswordCell {
  final int id;
  final int column;
  final int row;
  final String letter;
  final bool isRevealed;
  final bool isMainWordCell;
  final int? clueNumber;

  const CrosswordCell({
    required this.id,
    required this.column,
    required this.row,
    required this.letter,
    required this.isRevealed,
    required this.isMainWordCell,
    required this.clueNumber,
  });

  CrosswordCell reveal() => CrosswordCell(
    id: id,
    column: column,
    row: row,
    letter: letter,
    isRevealed: true,
    isMainWordCell: isMainWordCell,
    clueNumber: clueNumber,
  );
}

class CrosswordClue {
  final int number;
  final CrosswordEntry entry;

  const CrosswordClue({required this.number, required this.entry});
}

class CrosswordPuzzle {
  final String mainWord;
  final int columnCount;
  final int rowCount;
  final UnmodifiableListView<CrosswordCell> cells;
  final UnmodifiableListView<CrosswordClue> clues;
  final UnmodifiableListView<String> alphabet;

  CrosswordPuzzle({
    required this.mainWord,
    required this.columnCount,
    required this.rowCount,
    required List<CrosswordCell> cells,
    required List<CrosswordClue> clues,
    required List<String> alphabet,
  }) : cells = UnmodifiableListView(cells),
       clues = UnmodifiableListView(clues),
       alphabet = UnmodifiableListView(alphabet);
}
