import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/memory_card_data.dart';
import '../models/memory_pair.dart';

class MemoryController extends ChangeNotifier {
  static const int pairCount = 9;

  final List<MemoryPair> _pairs;
  final Random _random;
  final Duration revealDuration;

  List<MemoryCardData> _cards = const [];
  int? _firstCardId;
  int _revealCounter = 0;
  bool _isEvaluating = false;
  bool _disposed = false;

  MemoryController({
    required List<MemoryPair> pairs,
    Random? random,
    this.revealDuration = const Duration(milliseconds: 900),
  }) : _pairs = List.unmodifiable(pairs),
       _random = random ?? Random() {
    startNewGame(notify: false);
  }

  List<MemoryCardData> get cards => List.unmodifiable(_cards);
  bool get canPlay => _cards.length == pairCount * 2;
  bool get isComplete => canPlay && _cards.every((card) => card.isMatched);

  void startNewGame({bool notify = true}) {
    final available = [..._pairs]..shuffle(_random);
    final selected = available.take(pairCount).toList();
    final cards = selected.length < pairCount
        ? <MemoryCardData>[]
        : [
            for (final (index, pair) in selected.indexed) ...[
              MemoryCardData(
                cardId: index * 2,
                pairId: pair.id,
                kind: MemoryCardKind.word,
                content: pair.word,
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
    _isEvaluating = false;
    if (notify) notifyListeners();
  }

  Future<void> select(int cardId) async {
    if (_isEvaluating || !canPlay) return;
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
    if (_disposed) return;

    final first = _cardById(firstCardId);
    final second = _cardById(cardId);
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
