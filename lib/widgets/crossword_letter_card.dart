import 'package:flutter/material.dart';

import '../models/crossword_puzzle.dart';

class CrosswordAlphabetCard extends StatelessWidget {
  final String letter;
  final double size;
  final bool isSelected;
  final bool isEnabled;
  final ValueChanged<String> onSelect;

  const CrosswordAlphabetCard({
    required this.letter,
    required this.size,
    required this.isSelected,
    required this.isEnabled,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = SizedBox.square(
      dimension: size,
      child: Card(
        color: isSelected ? scheme.primary : scheme.tertiaryContainer,
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              color: isSelected ? scheme.onPrimary : scheme.onTertiaryContainer,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
    if (!isEnabled) return Opacity(opacity: 0.5, child: card);
    return Draggable<String>(
      data: letter,
      onDragStarted: isSelected ? null : () => onSelect(letter),
      feedback: Material(color: Colors.transparent, child: card),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: InkWell(onTap: () => onSelect(letter), child: card),
    );
  }
}

class CrosswordGridCell extends StatelessWidget {
  final CrosswordCell cell;
  final double size;
  final String? selectedLetter;
  final bool isEnabled;
  final bool Function({required int cellId, required String letter}) canPlace;
  final Future<void> Function(int cellId) onPlaceSelected;
  final Future<void> Function({required int cellId, required String letter})
  onPlace;

  const CrosswordGridCell({
    required this.cell,
    required this.size,
    required this.selectedLetter,
    required this.isEnabled,
    required this.canPlace,
    required this.onPlaceSelected,
    required this.onPlace,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final revealedColor = cell.isMainWordCell
        ? scheme.secondaryContainer
        : scheme.primaryContainer;
    final revealedTextColor = cell.isMainWordCell
        ? scheme.onSecondaryContainer
        : scheme.onPrimaryContainer;

    Widget buildCard(bool isCandidate) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cell.isRevealed
            ? revealedColor
            : isCandidate
            ? scheme.tertiaryContainer
            : scheme.surfaceContainerHighest,
        border: Border.all(color: scheme.outline, width: 1.5),
      ),
      child: Stack(
        children: [
          if (cell.clueNumber case final number?)
            Positioned(
              left: 3,
              top: 1,
              child: Text(
                '$number',
                style: TextStyle(
                  color: cell.isRevealed
                      ? revealedTextColor
                      : scheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ),
          Center(
            child: Text(
              cell.isRevealed ? cell.letter : '',
              style: TextStyle(
                color: revealedTextColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (cell.isRevealed || !isEnabled) return buildCard(false);
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          canPlace(cellId: cell.id, letter: details.data),
      onAcceptWithDetails: (details) =>
          onPlace(cellId: cell.id, letter: details.data),
      builder: (_, candidateData, _) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: selectedLetter == null ? null : () => onPlaceSelected(cell.id),
        child: buildCard(candidateData.isNotEmpty),
      ),
    );
  }
}
