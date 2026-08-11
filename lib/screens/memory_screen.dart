import 'package:flutter/material.dart';

import '../models/memory_board_layout.dart';
import '../models/memory_card_data.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/memory_card.dart';

class MemoryScreen extends StatelessWidget {
  static const _gap = 12.0;
  static const _minimumPadding = 24.0;
  static const _columnCount = 3;
  static const _rowCount = 6;

  final MemoryViewData viewData;
  final VoidCallback onBack;
  final Future<void> Function(int cardId) onSelect;
  final VoidCallback onNewGame;

  const MemoryScreen({
    required this.viewData,
    required this.onBack,
    required this.onSelect,
    required this.onNewGame,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FeatureAppBar(title: 'Memory cards', onBack: onBack),
      body: SafeArea(
        child: switch ((
          viewData.isLoading,
          viewData.errorMessage,
          viewData.cards.length,
        )) {
          (true, _, _) => const Center(child: CircularProgressIndicator()),
          (_, final String message, _) => Center(child: Text(message)),
          (_, _, 18) => _buildBoard(),
          _ => const Center(child: Text('Not enough word and image pairs.')),
        },
      ),
    );
  }

  Widget _buildBoard() => LayoutBuilder(
    builder: (_, constraints) {
      final board = MemoryBoardLayout.calculate(
        availableWidth: constraints.maxWidth,
        availableHeight: constraints.maxHeight,
        minimumPadding: _minimumPadding,
        gap: _gap,
        columnCount: _columnCount,
        rowCount: _rowCount,
      );
      final indexedCards = viewData.cards.indexed.toList();
      final faceUpCards =
          indexedCards.where((entry) => entry.$2.isFaceUp).toList()..sort(
            (first, second) =>
                first.$2.revealOrder.compareTo(second.$2.revealOrder),
          );
      final orderedCards = [
        ...indexedCards.where((entry) => !entry.$2.isFaceUp),
        ...faceUpCards,
      ];
      return Stack(
        clipBehavior: Clip.none,
        children: [
          for (final entry in orderedCards)
            _positionCard(board, entry.$1, entry.$2),
          if (viewData.isComplete)
            Positioned.fill(
              child: Center(
                child: FilledButton.icon(
                  onPressed: onNewGame,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Play again'),
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget _positionCard(
    MemoryBoardLayout board,
    int index,
    MemoryCardData card,
  ) {
    final position = board.positionFor(index);
    return Positioned(
      key: ValueKey(card.cardId),
      left: position.x,
      top: position.y,
      width: position.size,
      height: position.size,
      child: MemoryCard(
        data: card,
        expandedOffset: _expandedOffsetFor(index),
        onPressed: () => onSelect(card.cardId),
      ),
    );
  }

  Offset _expandedOffsetFor(int index) {
    final column = index % _columnCount;
    final row = index ~/ _columnCount;
    final dx = column == 0
        ? 0.5
        : column == _columnCount - 1
        ? -0.5
        : 0.0;
    return Offset(dx, row < _rowCount / 2 ? 0.5 : -0.5);
  }
}
