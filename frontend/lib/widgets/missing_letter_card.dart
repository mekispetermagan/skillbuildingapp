import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import '../models/missing_letter_slot.dart';
import '../models/missing_letter_tile.dart';

class MissingLetterCard extends StatelessWidget {
  final String letter;
  final Color backgroundColor;
  final Color foregroundColor;

  const MissingLetterCard({
    required this.letter,
    required this.backgroundColor,
    required this.foregroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: Card(
        color: backgroundColor,
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class DraggableMissingLetterCard extends StatelessWidget {
  final MissingLetterTile tile;
  final bool isSelected;
  final ValueChanged<int> onSelect;

  const DraggableMissingLetterCard({
    required this.tile,
    required this.isSelected,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = Container(
      decoration: BoxDecoration(
        border: isSelected ? Border.all(color: scheme.primary, width: 3) : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: MissingLetterCard(
        letter: tile.letter,
        backgroundColor: scheme.tertiaryContainer,
        foregroundColor: scheme.onTertiaryContainer,
      ),
    );
    return Draggable<MissingLetterTile>(
      data: tile,
      onDragStarted: isSelected ? null : () => onSelect(tile.id),
      feedback: Material(color: Colors.transparent, child: card),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: InkWell(onTap: () => onSelect(tile.id), child: card),
    );
  }
}

class MissingLetterTargetCard extends StatelessWidget {
  final MissingLetterSlot slot;
  final bool Function({required int targetId, required int tileId}) canDrop;
  final void Function({required int targetId, required int tileId}) onDrop;
  final int? selectedTileId;
  final ValueChanged<int> onPlaceSelected;

  const MissingLetterTargetCard({
    required this.slot,
    required this.canDrop,
    required this.onDrop,
    required this.selectedTileId,
    required this.onPlaceSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (slot.isFilled) {
      return MissingLetterCard(
        letter: slot.letter,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      );
    }

    return DragTarget<MissingLetterTile>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) =>
          onDrop(targetId: slot.id, tileId: details.data.id),
      builder: (_, candidateData, _) {
        final candidate = candidateData.firstOrNull;
        final isCorrect =
            candidate != null &&
            canDrop(targetId: slot.id, tileId: candidate.id);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: selectedTileId == null ? null : () => onPlaceSelected(slot.id),
          child: MissingLetterCard(
            letter: '?',
            backgroundColor: candidate == null || !isCorrect
                ? scheme.errorContainer
                : scheme.secondaryContainer,
            foregroundColor: candidate == null || !isCorrect
                ? scheme.onErrorContainer
                : scheme.onSecondaryContainer,
          ),
        );
      },
    );
  }
}
