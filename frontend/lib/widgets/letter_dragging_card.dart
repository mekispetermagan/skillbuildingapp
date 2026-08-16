import 'package:flutter/material.dart';

import '../models/letter_dragging_state.dart';
import '../models/letter_dragging_tile.dart';

class LetterDraggingCard extends StatelessWidget {
  final LetterDraggingTile tile;
  final int index;
  final LetterDraggingState state;
  final bool canDrag;

  const LetterDraggingCard({
    required this.tile,
    required this.index,
    required this.state,
    required this.canDrag,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final baseScheme = Theme.of(context).colorScheme;
    final colorScheme = state == LetterDraggingState.successFeedback
        ? ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: baseScheme.brightness,
          )
        : baseScheme;
    final card = Card(
      color: colorScheme.primaryContainer,
      child: SizedBox(
        width: 44,
        height: 52,
        child: Center(
          child: Text(
            tile.letter,
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );

    if (!canDrag) return card;
    return ReorderableDragStartListener(index: index, child: card);
  }
}
