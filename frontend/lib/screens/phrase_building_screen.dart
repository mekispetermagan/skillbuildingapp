import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

import '../models/phrase_building_tile.dart';
import '../models/phrase_building_state.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/feature_load_state.dart';
import '../widgets/phrase_building_card.dart';

class PhraseBuildingScreen extends StatelessWidget {
  final PhraseBuildingViewData viewData;
  final VoidCallback onBack;
  final void Function(PhraseBuildingTile)? onMove;
  final bool Function(PhraseBuildingTile) canMoveToTarget;
  final bool Function(PhraseBuildingTile) canMoveToSource;
  final ValueChanged<PhraseBuildingTile> onMoveToTarget;
  final ValueChanged<PhraseBuildingTile> onMoveToSource;
  final Future<void> Function()? onSubmit;
  final Future<void> Function() onPlayAudio;

  const PhraseBuildingScreen({
    required this.viewData,
    required this.onBack,
    required this.onMove,
    required this.canMoveToTarget,
    required this.canMoveToSource,
    required this.onMoveToTarget,
    required this.onMoveToSource,
    required this.onSubmit,
    required this.onPlayAudio,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FeatureAppBar(
        title: context.l10n.activityPhraseBuilding,
        onBack: onBack,
      ),
      body: FeatureLoadState(
        isLoading: viewData.isLoading,
        loadError: viewData.loadError,
        child: _buildExercise(context),
      ),
    );
  }

  Widget _buildExercise(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _PhrasePoolTarget(
                alignment: Alignment.bottomLeft,
                tiles: viewData.targetPool,
                state: viewData.state,
                onMove: onMove,
                canAccept: canMoveToTarget,
                onAccept: onMoveToTarget,
                keyPrefix: 'target',
              ),
            ),
            const Divider(height: 32),
            Expanded(
              child: _PhrasePoolTarget(
                alignment: Alignment.topLeft,
                tiles: viewData.sourcePool,
                state: viewData.state,
                onMove: onMove,
                canAccept: canMoveToSource,
                onAccept: onMoveToSource,
                keyPrefix: 'source',
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: onPlayAudio,
                  icon: const Icon(Icons.volume_up),
                  iconSize: 36,
                  tooltip: context.l10n.playSentence,
                ),
                FilledButton(
                  onPressed: onSubmit,
                  child: Text(context.l10n.check),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PhrasePoolTarget extends StatelessWidget {
  final Alignment alignment;
  final List<PhraseBuildingTile> tiles;
  final PhraseBuildingState state;
  final void Function(PhraseBuildingTile)? onMove;
  final bool Function(PhraseBuildingTile) canAccept;
  final ValueChanged<PhraseBuildingTile> onAccept;
  final String keyPrefix;

  const _PhrasePoolTarget({
    required this.alignment,
    required this.tiles,
    required this.state,
    required this.onMove,
    required this.canAccept,
    required this.onAccept,
    required this.keyPrefix,
  });

  @override
  Widget build(BuildContext context) => DragTarget<PhraseBuildingTile>(
    onWillAcceptWithDetails: (details) => canAccept(details.data),
    onAcceptWithDetails: (details) => onAccept(details.data),
    builder: (context, candidates, _) => AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: candidates.isEmpty
            ? null
            : Theme.of(context).colorScheme.primaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final tile in tiles)
            PhraseBuildingCard(
              key: ValueKey('$keyPrefix-${tile.id}'),
              tile: tile,
              state: state,
              onMove: onMove,
            ),
        ],
      ),
    ),
  );
}
