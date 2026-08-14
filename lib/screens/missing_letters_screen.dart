import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

import '../models/missing_letters_state.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/feature_load_state.dart';
import '../widgets/missing_letter_card.dart';
import '../widgets/image_visibility_segments.dart';
import '../widgets/reward_gem_row.dart';

class MissingLettersScreen extends StatelessWidget {
  final MissingLettersViewData viewData;
  final VoidCallback onBack;
  final VoidCallback? onNext;
  final bool Function({required int targetId, required int tileId}) canDrop;
  final void Function({required int targetId, required int tileId}) onDrop;
  final ValueChanged<int> onSelectTile;
  final ValueChanged<int> onPlaceSelected;
  final ValueChanged<bool> onShowImagesChanged;

  const MissingLettersScreen({
    required this.viewData,
    required this.onBack,
    required this.onNext,
    required this.canDrop,
    required this.onDrop,
    required this.onSelectTile,
    required this.onPlaceSelected,
    required this.onShowImagesChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FeatureAppBar(
        title: context.l10n.activityMissingLetters,
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
    final scheme = Theme.of(context).colorScheme;
    final imagePath = viewData.imagePath;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.instructionMissingLetters,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22),
            ),
            ImageVisibilitySegments(
              showImages: viewData.showImages,
              onChanged: onShowImagesChanged,
            ),
            if (viewData.showImages && imagePath != null)
              Image.asset(
                imagePath,
                width: 90,
                height: 90,
                fit: BoxFit.contain,
              ),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (final slot in viewData.slots)
                  slot.isMissing
                      ? MissingLetterTargetCard(
                          key: ValueKey('target-${slot.id}'),
                          slot: slot,
                          canDrop: canDrop,
                          onDrop: onDrop,
                          selectedTileId: viewData.selectedTileId,
                          onPlaceSelected: onPlaceSelected,
                        )
                      : MissingLetterCard(
                          key: ValueKey('letter-${slot.id}'),
                          letter: slot.letter,
                          backgroundColor: scheme.primaryContainer,
                          foregroundColor: scheme.onPrimaryContainer,
                        ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tile in viewData.pool)
                  DraggableMissingLetterCard(
                    key: ValueKey('pool-${tile.id}'),
                    tile: tile,
                    isSelected: viewData.selectedTileId == tile.id,
                    onSelect: onSelectTile,
                  ),
              ],
            ),
            RewardGemRow(count: viewData.score),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onNext,
                child: Text(
                  viewData.state == MissingLettersState.solved
                      ? context.l10n.next
                      : context.l10n.findBoth,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
