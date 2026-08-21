import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/image_word.dart';
import '../models/memory_card_data.dart';
import '../models/memory_config.dart';

const memoryConfig = MemoryConfig(pairCount: 9, columnCount: 3);

class MemoryController extends ChangeNotifier {
  final List<ImageWord> _pairs;
  final Random _random;
  final Duration revealDuration;
  final MemoryConfig config;

  List<MemoryCardData> _cards = const [];
  int? _firstCardId;
  int _revealCounter = 0;
  int _pairAttempts = 0;
  int _mismatches = 0;
  bool _isEvaluating = false;
  bool _disposed = false;
  int _gameGeneration = 0;

  MemoryController({
    required List<ImageWord> pairs,
    Random? random,
    this.config = memoryConfig,
    this.revealDuration = const Duration(milliseconds: 900),
  }) : _pairs = List.unmodifiable(pairs),
       _random = random ?? Random() {
    startNewGame(notify: false);
  }

  List<MemoryCardData> get cards => List.unmodifiable(_cards);
  bool get canPlay => _cards.length == config.cardCount;
  bool get isComplete => canPlay && _cards.every((card) => card.isMatched);
  int get pairAttempts => _pairAttempts;
  int get mismatches => _mismatches;
  int get matchedPairs => _cards.where((card) => card.isMatched).length ~/ 2;

  void stop() => _gameGeneration++;

  void startNewGame({bool notify = true}) {
    _gameGeneration++;
    final available = [..._pairs]..shuffle(_random);
    final selected = available.take(config.pairCount).toList();
    final cards = selected.length < config.pairCount
        ? <MemoryCardData>[]
        : [
            for (final (index, pair) in selected.indexed) ...[
              MemoryCardData(
                cardId: index * 2,
                pairId: pair.id,
                kind: MemoryCardKind.word,
                content: pair.displayWord,
              ),
              MemoryCardData(
                cardId: index * 2 + 1,
                pairId: pair.id,
                kind: MemoryCardKind.image,
                content: pair.imagePath,
              ),
            ],
          ];
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
    _setState(cardId, MemoryCardState.revealed, revealOrder: _revealCounter);
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
        ? MemoryCardState.matched
        : MemoryCardState.hidden;
    _setState(firstCardId, nextState);
    _setState(cardId, nextState);
    _firstCardId = null;
    _isEvaluating = false;
    notifyListeners();
  }

  MemoryCardData _cardById(int cardId) =>
      _cards.firstWhere((card) => card.cardId == cardId);

  void _setState(int cardId, MemoryCardState state, {int? revealOrder}) {
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
