import 'dart:math';

import '../models/crossword_config.dart';
import '../models/crossword_entry.dart';
import '../models/crossword_puzzle.dart';

class CrosswordGenerator {
  final List<CrosswordEntry> _entries;
  final CrosswordConfig config;
  final Random _random;

  CrosswordGenerator({
    required List<CrosswordEntry> entries,
    required this.config,
    Random? random,
  }) : _entries = List.unmodifiable(entries),
       _random = random ?? Random() {
    if (_entries.isEmpty) {
      throw ArgumentError.value(entries, 'entries', 'Must not be empty');
    }
  }

  CrosswordPuzzle generate({Set<String> excludedMainWords = const {}}) {
    final mainCandidates = _entries
        .where(
          (entry) =>
              entry.word.length <= config.maximumGridSize &&
              !excludedMainWords.contains(entry.word),
        )
        .toList();
    if (mainCandidates.isEmpty) mainCandidates.addAll(_entries);
    mainCandidates.shuffle(_random);
    final candidatesToTry = mainCandidates.take(config.generationAttempts);
    for (final main in candidatesToTry) {
      final placements = _findPlacements(main);
      if (placements != null) return _buildPuzzle(main, placements);
    }
    throw StateError('Could not generate a crossword from this vocabulary.');
  }

  List<_Placement>? _findPlacements(CrosswordEntry main) {
    final options = <List<_Placement>>[];
    for (final letter in main.word.split('')) {
      final matches = <_Placement>[];
      for (final entry in _entries) {
        if (entry == main) continue;
        for (var crossing = 0; crossing < entry.word.length; crossing++) {
          if (entry.word[crossing] == letter) {
            matches.add(_Placement(entry: entry, crossing: crossing));
          }
        }
      }
      if (matches.isEmpty) return null;
      matches.shuffle(_random);
      options.add(matches);
    }

    List<_Placement>? search(
      int column,
      List<_Placement> chosen,
      Set<String> used,
    ) {
      if (column == options.length) return chosen;
      for (final placement in options[column]) {
        if (used.contains(placement.entry.word)) continue;
        final next = [...chosen, placement];
        final before = next.map((item) => item.crossing).reduce(max);
        final after = next
            .map((item) => item.entry.word.length - item.crossing - 1)
            .reduce(max);
        if (before + after + 1 > config.maximumGridSize) continue;
        final result = search(column + 1, next, {
          ...used,
          placement.entry.word,
        });
        if (result != null) return result;
      }
      return null;
    }

    return search(0, const [], {main.word});
  }

  CrosswordPuzzle _buildPuzzle(
    CrosswordEntry main,
    List<_Placement> placements,
  ) {
    final mainRow = placements.map((item) => item.crossing).reduce(max);
    final rowCount =
        mainRow +
        placements
            .map((item) => item.entry.word.length - item.crossing - 1)
            .reduce(max) +
        1;
    final revealableIds = <int>[];
    final cells = <CrosswordCell>[];

    for (final (column, placement) in placements.indexed) {
      final startRow = mainRow - placement.crossing;
      for (
        var wordIndex = 0;
        wordIndex < placement.entry.word.length;
        wordIndex++
      ) {
        final id = column * config.maximumGridSize + startRow + wordIndex;
        revealableIds.add(id);
        cells.add(
          CrosswordCell(
            id: id,
            column: column,
            row: startRow + wordIndex,
            letter: placement.entry.word[wordIndex],
            isRevealed: false,
            isMainWordCell: wordIndex == placement.crossing,
            clueNumber: wordIndex == 0 ? column + 1 : null,
          ),
        );
      }
    }

    revealableIds.shuffle(_random);
    final revealCount = (revealableIds.length * config.revealFraction).round();
    final revealedIds = revealableIds.take(revealCount).toSet();
    final preparedCells = [
      for (final cell in cells)
        revealedIds.contains(cell.id) ? cell.reveal() : cell,
    ];
    final alphabet = {
      for (final cell in preparedCells)
        if (!cell.isRevealed) cell.letter,
    }.toList()..sort();

    return CrosswordPuzzle(
      mainWord: main.word,
      columnCount: main.word.length,
      rowCount: rowCount,
      cells: preparedCells,
      clues: [
        for (final (index, placement) in placements.indexed)
          CrosswordClue(number: index + 1, entry: placement.entry),
      ],
      alphabet: alphabet,
    );
  }
}

class _Placement {
  final CrosswordEntry entry;
  final int crossing;

  const _Placement({required this.entry, required this.crossing});
}
