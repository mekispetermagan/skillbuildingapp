import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../models/missing_letter_slot.dart';
import '../models/missing_letter_tile.dart';
import '../models/missing_letters_state.dart';
import '../models/missing_letters_word.dart';

const missingLettersWinningScore = 10;

class MissingLettersController extends ChangeNotifier {
  final List<MissingLettersWord> _words;
  final Random _random;
  final Duration completionFeedbackDuration;
  late final List<String> _alphabet;
  final List<MissingLetterSlot> _slots = [];
  final List<MissingLetterTile> _pool = [];

  List<MissingLettersWord> _deck = [];
  int _deckIndex = 0;
  int _score = 0;
  int _incorrectAttempts = 0;
  bool _showImages = true;
  MissingLettersWord? _currentWord;
  MissingLettersState _state = MissingLettersState.solving;
  int? _selectedTileId;
  int _sessionGeneration = 0;
  bool _disposed = false;

  MissingLettersController({
    required List<MissingLettersWord> words,
    Random? random,
    this.completionFeedbackDuration = const Duration(seconds: 1),
  }) : _words = List.unmodifiable(words),
       _random = random ?? Random() {
    if (_words.isEmpty) {
      throw ArgumentError.value(words, 'words', 'Must not be empty');
    }
    _alphabet = {
      ...'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''),
      ..._words.expand((word) => word.letterTokens),
    }.toList(growable: false);
    start();
  }

  List<MissingLetterSlot> get slots => List.unmodifiable(_slots);
  List<MissingLetterTile> get pool => List.unmodifiable(_pool);
  MissingLettersState get state => _state;
  int get score => _score;
  int get incorrectAttempts => _incorrectAttempts;
  String? get imagePath => _currentWord?.imagePath;
  bool get showImages => _showImages;
  int? get selectedTileId => _selectedTileId;

  void selectTile(int tileId) {
    if (_state != MissingLettersState.solving ||
        !_pool.any((tile) => tile.id == tileId)) {
      return;
    }
    _selectedTileId = _selectedTileId == tileId ? null : tileId;
    notifyListeners();
  }

  void placeSelected(int targetId) {
    final tileId = _selectedTileId;
    if (tileId == null) return;
    drop(targetId: targetId, tileId: tileId);
  }

  bool canDrop({required int targetId, required int tileId}) {
    if (_state != MissingLettersState.solving) return false;
    final slot = _slots.where((item) => item.id == targetId).firstOrNull;
    final tile = _pool.where((item) => item.id == tileId).firstOrNull;
    return slot != null &&
        tile != null &&
        slot.isMissing &&
        !slot.isFilled &&
        slot.letter == tile.letter;
  }

  void start() {
    _sessionGeneration++;
    _score = 0;
    _incorrectAttempts = 0;
    _showImages = true;
    _deck = _words.shuffled(_random);
    _deckIndex = 0;
    _currentWord = null;
    _selectedTileId = null;
    _generateExercise();
    notifyListeners();
  }

  void setShowImages(bool value) {
    if (_showImages == value) return;
    _showImages = value;
    notifyListeners();
  }

  void drop({required int targetId, required int tileId}) {
    final slotIndex = _slots.indexWhere((slot) => slot.id == targetId);
    final tileIndex = _pool.indexWhere((tile) => tile.id == tileId);
    if (!canDrop(targetId: targetId, tileId: tileId)) {
      if (_state == MissingLettersState.solving &&
          slotIndex >= 0 &&
          tileIndex >= 0) {
        _incorrectAttempts++;
      }
      return;
    }

    final slot = _slots[slotIndex];
    final tile = _pool[tileIndex];
    _slots[slotIndex] = slot.fillWith(tile.id);
    _pool.removeAt(tileIndex);
    _selectedTileId = null;
    if (_slots.every((item) => item.isFilled)) {
      _state = MissingLettersState.solved;
      _score++;
      notifyListeners();
      unawaited(_advanceAfterFeedback());
      return;
    }
    notifyListeners();
  }

  Future<void> _advanceAfterFeedback() async {
    final generation = _sessionGeneration;
    await Future<void>.delayed(completionFeedbackDuration);
    if (_disposed || generation != _sessionGeneration) return;
    if (_score >= missingLettersWinningScore) {
      _state = MissingLettersState.won;
      notifyListeners();
      return;
    }
    _generateExercise();
    notifyListeners();
  }

  void _generateExercise() {
    if (_deckIndex == _deck.length) {
      final previous = _currentWord;
      _deck = _words.shuffled(_random);
      if (_deck.length > 1 && _deck.first == previous) {
        final first = _deck.removeAt(0);
        _deck.add(first);
      }
      _deckIndex = 0;
    }

    final word = _deck[_deckIndex++];
    _currentWord = word;
    _state = MissingLettersState.solving;
    _selectedTileId = null;
    final letters = word.letterTokens;
    final missingIndices = [
      for (var index = 0; index < letters.length; index++) index,
    ].shuffled(_random).take(2).toSet();
    final requiredLetters = [
      for (final index in missingIndices) letters[index],
    ];

    _slots
      ..clear()
      ..addAll([
        for (final (index, letter) in letters.indexed)
          MissingLetterSlot(
            id: index,
            letter: letter,
            isMissing: missingIndices.contains(index),
          ),
      ]);

    final distractors = _alphabet
        .where((letter) => !requiredLetters.contains(letter))
        .shuffled(_random)
        .take(5);
    final poolLetters = [...requiredLetters, ...distractors].shuffled(_random);
    _pool
      ..clear()
      ..addAll([
        for (final (index, letter) in poolLetters.indexed)
          MissingLetterTile(id: index, letter: letter),
      ]);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
