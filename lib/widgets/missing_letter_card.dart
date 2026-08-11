import 'package:flutter/material.dart';

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

  const DraggableMissingLetterCard({required this.tile, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = MissingLetterCard(
      letter: tile.letter,
      backgroundColor: scheme.tertiaryContainer,
      foregroundColor: scheme.onTertiaryContainer,
    );
    return Draggable<MissingLetterTile>(
      data: tile,
      feedback: Material(color: Colors.transparent, child: card),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: card,
    );
  }
}

class MissingLetterTargetCard extends StatelessWidget {
  final MissingLetterSlot slot;
  final bool Function({required int targetId, required int tileId}) canDrop;
  final void Function({required int targetId, required int tileId}) onDrop;

  const MissingLetterTargetCard({
    required this.slot,
    required this.canDrop,
    required this.onDrop,
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
      onWillAcceptWithDetails: (details) =>
          canDrop(targetId: slot.id, tileId: details.data.id),
      onAcceptWithDetails: (details) =>
          onDrop(targetId: slot.id, tileId: details.data.id),
      builder: (_, candidateData, _) => MissingLetterCard(
        letter: '?',
        backgroundColor: candidateData.isEmpty
            ? scheme.errorContainer
            : scheme.secondaryContainer,
        foregroundColor: candidateData.isEmpty
            ? scheme.onErrorContainer
            : scheme.onSecondaryContainer,
      ),
    );
  }
}
