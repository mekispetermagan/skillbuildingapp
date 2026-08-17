import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/memory_config.dart';
import '../models/number_memory.dart';
import 'number_learning_controller.dart';

const numberMemoryConfig = MemoryConfig(pairCount: 9, columnCount: 3);

class NumberMemoryController extends ChangeNotifier {
  final Random _random;
  final Duration revealDuration;
  final MemoryConfig config;
  List<NumberMemoryCardData> _cards = const [];
  NumberMemoryRange _range = NumberMemoryRange.oneToTwelve;
  int? _firstCardId;
  int _revealCounter = 0;
  int _pairAttempts = 0;
  int _mismatches = 0;
  bool _isEvaluating = false;
  bool _disposed = false;
  int _gameGeneration = 0;

  NumberMemoryController({
    Random? random,
    this.config = numberMemoryConfig,
    this.revealDuration = const Duration(milliseconds: 900),
  }) : _random = random ?? Random() {
    startNewGame(notify: false);
  }

  List<NumberMemoryCardData> get cards => List.unmodifiable(_cards);
  NumberMemoryRange get range => _range;
  bool get canPlay => _cards.length == config.cardCount;
  bool get isComplete => canPlay && _cards.every((card) => card.isMatched);
  int get pairAttempts => _pairAttempts;
  int get mismatches => _mismatches;
  int get matchedPairs => _cards.where((card) => card.isMatched).length ~/ 2;
  int get maximumNumber => _range == NumberMemoryRange.oneToTwelve ? 12 : 24;
  int get quantityGridSize => _range == NumberMemoryRange.oneToTwelve ? 4 : 5;

  void stop() => _gameGeneration++;

  void setRange(NumberMemoryRange value) {
    if (_range == value) return;
    _range = value;
    startNewGame();
  }

  void startNewGame({bool notify = true}) {
    _gameGeneration++;
    final available = [
      for (var number = 1; number <= maximumNumber; number++) number,
    ]..shuffle(_random);
    final selected = available.take(config.pairCount);
    final cards = <NumberMemoryCardData>[];
    for (final (index, number) in selected.indexed) {
      final emoji = numberEmojis[_random.nextInt(numberEmojis.length)];
      final cells = [
        for (var cell = 0; cell < quantityGridSize * quantityGridSize; cell++)
          cell,
      ]..shuffle(_random);
      cards.addAll([
        NumberMemoryCardData(
          cardId: index * 2,
          pairId: number,
          kind: NumberMemoryCardKind.numeral,
          number: number,
          emoji: emoji,
          positions: const [],
          gridSize: quantityGridSize,
        ),
        NumberMemoryCardData(
          cardId: index * 2 + 1,
          pairId: number,
          kind: NumberMemoryCardKind.quantity,
          number: number,
          emoji: emoji,
          positions: cells.take(number).toList(growable: false),
          gridSize: quantityGridSize,
        ),
      ]);
    }
    cards.shuffle(_random);
    _cards = cards;
    _firstCardId = null;
    _revealCounter = 0;
    _pairAttempts = 0;
    _mismatches = 0;
    _isEvaluating = false;
    if (notify) notifyListeners();
  }

  Future<void> select(int cardId) async {
    if (_isEvaluating || !canPlay) return;
    final generation = _gameGeneration;
    final selectedIndex = _cards.indexWhere((card) => card.cardId == cardId);
    if (selectedIndex == -1 || _cards[selectedIndex].isFaceUp) return;
    _revealCounter++;
    _setState(
      cardId,
      NumberMemoryCardState.revealed,
      revealOrder: _revealCounter,
    );
    final firstCardId = _firstCardId;
    if (firstCardId == null) {
      _firstCardId = cardId;
      notifyListeners();
      return;
    }
    _isEvaluating = true;
    notifyListeners();
    await Future<void>.delayed(revealDuration);
    if (_disposed || generation != _gameGeneration) return;
    final first = _cardById(firstCardId);
    final second = _cardById(cardId);
    _pairAttempts++;
    if (first.pairId != second.pairId) _mismatches++;
    final nextState = first.pairId == second.pairId
        ? NumberMemoryCardState.matched
        : NumberMemoryCardState.hidden;
    _setState(firstCardId, nextState);
    _setState(cardId, nextState);
    _firstCardId = null;
    _isEvaluating = false;
    notifyListeners();
  }

  NumberMemoryCardData _cardById(int cardId) =>
      _cards.firstWhere((card) => card.cardId == cardId);

  void _setState(int cardId, NumberMemoryCardState state, {int? revealOrder}) {
    _cards = [
      for (final card in _cards)
        if (card.cardId == cardId)
          card.copyWith(state: state, revealOrder: revealOrder)
        else
          card,
    ];
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
