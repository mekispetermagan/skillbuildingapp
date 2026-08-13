import 'dart:math';

import 'package:characters/characters.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../models/missing_letter_slot.dart';
import '../models/missing_letter_tile.dart';
import '../models/missing_letters_state.dart';
import '../models/missing_letters_word.dart';

class MissingLettersController extends ChangeNotifier {
  static final List<String> _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.characters
      .toList();

  final List<MissingLettersWord> _words;
  final Random _random;
  final List<MissingLetterSlot> _slots = [];
  final List<MissingLetterTile> _pool = [];

  List<MissingLettersWord> _deck = [];
  int _deckIndex = 0;
  int _score = 0;
  MissingLettersWord? _currentWord;
  MissingLettersState _state = MissingLettersState.solving;
  int? _selectedTileId;

  MissingLettersController({
    required List<MissingLettersWord> words,
    Random? random,
  }) : _words = List.unmodifiable(words),
       _random = random ?? Random() {
    if (_words.isEmpty) {
      throw ArgumentError.value(words, 'words', 'Must not be empty');
    }
    start();
  }

  List<MissingLetterSlot> get slots => List.unmodifiable(_slots);
  List<MissingLetterTile> get pool => List.unmodifiable(_pool);
  MissingLettersState get state => _state;
  int get score => _score;
  bool get canContinue => _state == MissingLettersState.solved;
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
    _score = 0;
    _deck = _words.shuffled(_random);
    _deckIndex = 0;
    _currentWord = null;
    _selectedTileId = null;
    _generateExercise();
    notifyListeners();
  }

  void drop({required int targetId, required int tileId}) {
    final slotIndex = _slots.indexWhere((slot) => slot.id == targetId);
    final tileIndex = _pool.indexWhere((tile) => tile.id == tileId);
    if (!canDrop(targetId: targetId, tileId: tileId)) return;

    final slot = _slots[slotIndex];
    final tile = _pool[tileIndex];
    _slots[slotIndex] = slot.fillWith(tile.id);
    _pool.removeAt(tileIndex);
    _selectedTileId = null;
    if (_slots.every((item) => item.isFilled)) {
      _state = MissingLettersState.solved;
      _score++;
    }
    notifyListeners();
  }

  void next() {
    if (!canContinue) return;
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
    final letters = word.word.characters.toList();
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
}
