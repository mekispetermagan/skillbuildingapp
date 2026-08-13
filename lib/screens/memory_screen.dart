import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

import '../models/memory_board_layout.dart';
import '../models/memory_card_data.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/feature_load_state.dart';
import '../widgets/memory_card.dart';

class MemoryScreen extends StatelessWidget {
  static const _gap = 12.0;
  static const _minimumPadding = 24.0;
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
      appBar: FeatureAppBar(
        title: context.l10n.activityMemoryCards,
        onBack: onBack,
      ),
      body: SafeArea(
        child: FeatureLoadState(
          isLoading: viewData.isLoading,
          loadError: viewData.loadError,
          child: viewData.cards.length == viewData.config.cardCount
              ? _buildBoard(context)
              : Center(child: Text(context.l10n.memoryNotEnoughPairs)),
        ),
      ),
    );
  }

  Widget _buildBoard(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final board = MemoryBoardLayout.calculate(
        availableWidth: constraints.maxWidth,
        availableHeight: constraints.maxHeight,
        minimumPadding: _minimumPadding,
        gap: _gap,
        columnCount: viewData.config.columnCount,
        rowCount: viewData.config.rowCount,
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
                  label: Text(context.l10n.playAgain),
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
    final column = index % viewData.config.columnCount;
    final row = index ~/ viewData.config.columnCount;
    final dx = column == 0
        ? 0.5
        : column == viewData.config.columnCount - 1
        ? -0.5
        : 0.0;
    return Offset(dx, row < viewData.config.rowCount / 2 ? 0.5 : -0.5);
  }
}
