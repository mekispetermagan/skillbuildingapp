import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/memory_board_layout.dart';
import '../models/number_memory.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/single_select_segments.dart';

class NumberMemoryScreen extends StatelessWidget {
  static const _gap = 12.0;
  static const _minimumPadding = 24.0;
  final NumberMemoryViewData viewData;
  final VoidCallback onBack;
  final Future<void> Function(int cardId) onSelect;
  final VoidCallback onNewGame;
  final ValueChanged<NumberMemoryRange> onSetRange;

  const NumberMemoryScreen({
    required this.viewData,
    required this.onBack,
    required this.onSelect,
    required this.onNewGame,
    required this.onSetRange,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(
      title: context.l10n.activityNumberMemory,
      onBack: onBack,
    ),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SingleSelectSegments<NumberMemoryRange>(
              choices: const [
                SegmentChoice(
                  value: NumberMemoryRange.oneToTwelve,
                  label: '1–12',
                ),
                SegmentChoice(
                  value: NumberMemoryRange.oneToTwentyFour,
                  label: '1–24',
                ),
              ],
              selected: viewData.range,
              onSelected: onSetRange,
            ),
          ),
          Expanded(child: _buildBoard(context)),
        ],
      ),
    ),
  );

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
    NumberMemoryCardData card,
  ) {
    final position = board.positionFor(index);
    return Positioned(
      key: ValueKey(card.cardId),
      left: position.x,
      top: position.y,
      width: position.size,
      height: position.size,
      child: _NumberMemoryCard(
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

class _NumberMemoryCard extends StatelessWidget {
  static const _flipDuration = Duration(milliseconds: 450);
  static const _hideDuration = Duration(milliseconds: 350);
  final NumberMemoryCardData data;
  final Offset expandedOffset;
  final VoidCallback onPressed;

  const _NumberMemoryCard({
    required this.data,
    required this.expandedOffset,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: data.isFaceUp,
    child: AnimatedOpacity(
      opacity: data.isMatched ? 0 : 1,
      duration: _hideDuration,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: data.isFaceUp ? expandedOffset : Offset.zero,
        duration: _flipDuration,
        curve: Curves.easeInOutCubic,
        child: AnimatedScale(
          scale: data.isFaceUp ? 2 : 1,
          duration: _flipDuration,
          curve: Curves.easeInOutCubic,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: data.isFaceUp ? 1 : 0),
            duration: _flipDuration,
            curve: Curves.easeInOutCubic,
            builder: (context, turn, _) {
              final showFace = turn >= 0.5;
              final rotation = Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(math.pi * turn);
              return Transform(
                alignment: Alignment.center,
                transform: rotation,
                child: showFace
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(math.pi),
                        child: _NumberCardFace(data: data),
                      )
                    : _NumberCardBack(kind: data.kind, onPressed: onPressed),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _NumberCardBack extends StatelessWidget {
  final NumberMemoryCardKind kind;
  final VoidCallback onPressed;

  const _NumberCardBack({required this.kind, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isNumeral = kind == NumberMemoryCardKind.numeral;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: isNumeral ? colors.primaryContainer : colors.tertiaryContainer,
      child: InkWell(
        onTap: onPressed,
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              color: isNumeral
                  ? colors.onPrimaryContainer
                  : colors.onTertiaryContainer,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberCardFace extends StatelessWidget {
  final NumberMemoryCardData data;

  const _NumberCardFace({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isNumeral = data.kind == NumberMemoryCardKind.numeral;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: isNumeral ? colors.primary : colors.tertiary,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: isNumeral
            ? Center(
                child: FittedBox(
                  child: Text(
                    '${data.number}',
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : _ScatteredEmojis(data: data),
      ),
    );
  }
}

class _ScatteredEmojis extends StatelessWidget {
  final NumberMemoryCardData data;

  const _ScatteredEmojis({required this.data});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final cellWidth = constraints.maxWidth / data.gridSize;
      final cellHeight = constraints.maxHeight / data.gridSize;
      return Stack(
        children: [
          for (final position in data.positions)
            Positioned(
              left: position % data.gridSize * cellWidth,
              top: position ~/ data.gridSize * cellHeight,
              width: cellWidth,
              height: cellHeight,
              child: FittedBox(fit: BoxFit.contain, child: Text(data.emoji)),
            ),
        ],
      );
    },
  );
}
