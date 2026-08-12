import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/crossword_config.dart';
import '../models/crossword_entry.dart';
import '../models/crossword_puzzle.dart';
import '../models/crossword_state.dart';
import 'crossword_generator.dart';

const crosswordConfig = CrosswordConfig(
  cellSize: 48,
  alphabetCellSize: 48,
  maximumGridSize: 6,
  revealFraction: 0.5,
  winningScore: 3,
  generationAttempts: 100,
  completedCrosswordDuration: Duration(seconds: 1),
);

class CrosswordController extends ChangeNotifier {
  final CrosswordGenerator _generator;
  final CrosswordConfig config;

  late CrosswordPuzzle puzzle;
  CrosswordState state = CrosswordState.playing;
  int score = 0;
  String? selectedLetter;
  bool _disposed = false;
  int _sessionGeneration = 0;
  final Set<String> _mainWordHistory = {};

  CrosswordController({
    required List<CrosswordEntry> entries,
    this.config = crosswordConfig,
    Random? random,
  }) : _generator = CrosswordGenerator(
         entries: entries,
         config: config,
         random: random,
       ) {
    start();
  }

  bool get canPlay => state == CrosswordState.playing;

  void start() {
    _sessionGeneration++;
    score = 0;
    state = CrosswordState.playing;
    selectedLetter = null;
    _mainWordHistory.clear();
    _generatePuzzle();
    notifyListeners();
  }

  void stop() => _sessionGeneration++;

  void selectLetter(String letter) {
    if (!canPlay || !puzzle.alphabet.contains(letter)) return;
    selectedLetter = selectedLetter == letter ? null : letter;
    notifyListeners();
  }

  bool canPlace({required int cellId, required String letter}) {
    if (!canPlay || !puzzle.alphabet.contains(letter)) return false;
    final index = puzzle.cells.indexWhere((cell) => cell.id == cellId);
    return index >= 0 &&
        !puzzle.cells[index].isRevealed &&
        puzzle.cells[index].letter == letter;
  }

  Future<void> placeSelected(int cellId) async {
    final letter = selectedLetter;
    if (letter == null) return;
    await place(cellId: cellId, letter: letter);
  }

  Future<void> place({required int cellId, required String letter}) async {
    if (!canPlace(cellId: cellId, letter: letter)) return;
    final cells = puzzle.cells.toList();
    final index = cells.indexWhere((cell) => cell.id == cellId);
    cells[index] = cells[index].reveal();
    selectedLetter = null;
    puzzle = CrosswordPuzzle(
      mainWord: puzzle.mainWord,
      columnCount: puzzle.columnCount,
      rowCount: puzzle.rowCount,
      cells: cells,
      clues: puzzle.clues,
      alphabet: puzzle.alphabet,
    );

    if (cells.every((cell) => cell.isRevealed)) {
      await _completePuzzle();
    } else {
      notifyListeners();
    }
  }

  Future<void> _completePuzzle() async {
    final generation = _sessionGeneration;
    score++;
    state = CrosswordState.completed;
    notifyListeners();
    await Future<void>.delayed(config.completedCrosswordDuration);
    if (_disposed || generation != _sessionGeneration) return;
    if (score >= config.winningScore) {
      state = CrosswordState.won;
    } else {
      state = CrosswordState.playing;
      _generatePuzzle();
    }
    notifyListeners();
  }

  void _generatePuzzle() {
    puzzle = _generator.generate(excludedMainWords: _mainWordHistory);
    _mainWordHistory.add(puzzle.mainWord);
    selectedLetter = null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
