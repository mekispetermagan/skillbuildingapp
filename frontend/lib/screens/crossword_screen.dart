import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

import '../models/crossword_puzzle.dart';
import '../models/crossword_state.dart';
import '../models/view_data.dart';
import '../widgets/crossword_letter_card.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/feature_load_state.dart';
import '../widgets/game_end_overlay.dart';
import '../widgets/reward_gem_row.dart';

class CrosswordScreen extends StatelessWidget {
  final CrosswordViewData viewData;
  final VoidCallback onBack;
  final VoidCallback onRestart;
  final ValueChanged<String> onSelectLetter;
  final bool Function({required int cellId, required String letter}) canPlace;
  final Future<void> Function(int cellId) onPlaceSelected;
  final Future<void> Function({required int cellId, required String letter})
  onPlace;

  const CrosswordScreen({
    required this.viewData,
    required this.onBack,
    required this.onRestart,
    required this.onSelectLetter,
    required this.canPlace,
    required this.onPlaceSelected,
    required this.onPlace,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(
      title: context.l10n.activityCrossword,
      onBack: onBack,
    ),
    body: FeatureLoadState(
      isLoading: viewData.isLoading,
      loadError: viewData.loadError,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: switch (viewData.puzzle) {
                final puzzle? => _CrosswordContent(
                  viewData: viewData,
                  puzzle: puzzle,
                  onSelectLetter: onSelectLetter,
                  canPlace: canPlace,
                  onPlaceSelected: onPlaceSelected,
                  onPlace: onPlace,
                ),
                null => const SizedBox.shrink(),
              },
            ),
            if (viewData.state == CrosswordState.won)
              Positioned.fill(
                child: GameEndOverlay(
                  message: context.l10n.congratulations,
                  onRestart: onRestart,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _CrosswordContent extends StatelessWidget {
  final CrosswordViewData viewData;
  final CrosswordPuzzle puzzle;
  final ValueChanged<String> onSelectLetter;
  final bool Function({required int cellId, required String letter}) canPlace;
  final Future<void> Function(int cellId) onPlaceSelected;
  final Future<void> Function({required int cellId, required String letter})
  onPlace;

  const _CrosswordContent({
    required this.viewData,
    required this.puzzle,
    required this.onSelectLetter,
    required this.canPlace,
    required this.onPlaceSelected,
    required this.onPlace,
  });

  @override
  Widget build(BuildContext context) {
    final config = viewData.config;
    final canPlay = viewData.state == CrosswordState.playing;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(
            children: [
              Text(
                context.l10n.instructionCrossword,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: puzzle.columnCount * config.cellSize,
                  height: puzzle.rowCount * config.cellSize,
                  child: Stack(
                    children: [
                      for (final cell in puzzle.cells)
                        Positioned(
                          key: ValueKey('crossword-cell-${cell.id}'),
                          left: cell.column * config.cellSize,
                          top: cell.row * config.cellSize,
                          child: CrosswordGridCell(
                            cell: cell,
                            size: config.cellSize,
                            selectedLetter: viewData.selectedLetter,
                            isEnabled: canPlay,
                            canPlace: canPlace,
                            onPlaceSelected: onPlaceSelected,
                            onPlace: onPlace,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final letter in puzzle.alphabet)
                    CrosswordAlphabetCard(
                      key: ValueKey('crossword-letter-$letter'),
                      letter: letter,
                      size: config.alphabetCellSize,
                      isSelected: viewData.selectedLetter == letter,
                      isEnabled: canPlay,
                      onSelect: onSelectLetter,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              for (final clue in puzzle.clues)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    '${clue.number}. ${clue.entry.clue}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              const SizedBox(height: 16),
              RewardGemRow(count: viewData.score),
            ],
          ),
        ),
      ],
    );
  }
}
