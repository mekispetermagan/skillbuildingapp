import 'package:flutter/material.dart';

import '../models/phrase_building_state.dart';
import '../models/phrase_building_tile.dart';

class PhraseBuildingCard extends StatelessWidget {
  final PhraseBuildingTile tile;
  final PhraseBuildingState state;
  final void Function(PhraseBuildingTile)? onMove;

  const PhraseBuildingCard({
    required this.tile,
    required this.state,
    required this.onMove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final baseScheme = Theme.of(context).colorScheme;
    final colorScheme = switch (state) {
      PhraseBuildingState.guessing || PhraseBuildingState.won => baseScheme,
      PhraseBuildingState.successFeedback => ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: baseScheme.brightness,
      ),
      PhraseBuildingState.failureFeedback => ColorScheme.fromSeed(
        seedColor: Colors.red,
        brightness: baseScheme.brightness,
      ),
    };

    final card = Card(
      color: colorScheme.secondaryContainer,
      child: InkWell(
        onTap: onMove == null ? null : () => onMove!(tile),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Text(
            tile.word,
            style: TextStyle(
              color: colorScheme.onSecondaryContainer,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
    if (onMove == null) return card;
    return Draggable<PhraseBuildingTile>(
      data: tile,
      feedback: Material(color: Colors.transparent, child: card),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: card,
    );
  }
}
