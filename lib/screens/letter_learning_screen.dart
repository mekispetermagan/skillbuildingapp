import 'package:flutter/material.dart';

import '../models/alphabet_letter.dart';
import '../models/letter_learning_state.dart';
import '../models/view_data.dart';
import '../widgets/alphabet_color.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/feature_load_state.dart';
import '../widgets/game_end_overlay.dart';
import '../widgets/letter_learning_cards.dart';
import '../widgets/reward_gem_row.dart';

class LetterLearningScreen extends StatelessWidget {
  final LetterLearningViewData viewData;
  final VoidCallback onBack;
  final VoidCallback onRestart;
  final ValueChanged<Set<AlphabetDifficulty>> onSetDifficulties;
  final ValueChanged<LetterLearningMode> onSetMode;
  final ValueChanged<String> onGuess;
  final Future<void> Function() onPlayAudio;

  const LetterLearningScreen({
    required this.viewData,
    required this.onBack,
    required this.onRestart,
    required this.onSetDifficulties,
    required this.onSetMode,
    required this.onGuess,
    required this.onPlayAudio,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(title: 'Letter learning', onBack: onBack),
    body: FeatureLoadState(
      isLoading: viewData.isLoading,
      errorMessage: viewData.errorMessage,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child:
                  viewData.currentObject == null ||
                      viewData.currentLetter == null
                  ? const SizedBox.shrink()
                  : CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverList.list(
                            children: [
                              _Controls(
                                difficulties: viewData.difficulties,
                                mode: viewData.mode,
                                onSetDifficulties: onSetDifficulties,
                                onSetMode: onSetMode,
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: Container(
                                  width: 200,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: alphabetColor(
                                        viewData.currentLetter!.colorName,
                                      ),
                                      width: 8,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Stack(
                                    children: [
                                      const Center(
                                        child: Icon(
                                          Icons.image_outlined,
                                          size: 64,
                                        ),
                                      ),
                                      Positioned(
                                        right: 4,
                                        bottom: 4,
                                        child: IconButton.filled(
                                          onPressed: onPlayAudio,
                                          icon: const Icon(Icons.volume_up),
                                          tooltip: 'Play letter and word',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  for (final slot in viewData.slots)
                                    LetterLearningWordCard(
                                      key: ValueKey(
                                        'letter-learning-slot-${slot.id}',
                                      ),
                                      slot: slot,
                                      size: viewData.config.targetCellSize,
                                      revealTarget: viewData.isTargetRevealed,
                                      isEnabled: viewData.canGuess,
                                      onGuess: onGuess,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        viewData.sourceColumnCount *
                                        (viewData.config.sourceCellSize + 4),
                                  ),
                                  child: GridView.count(
                                    crossAxisCount: viewData.sourceColumnCount,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    mainAxisSpacing: 4,
                                    crossAxisSpacing: 4,
                                    children: [
                                      for (final letter
                                          in viewData.sourceLetters)
                                        LetterLearningSourceCard(
                                          key: ValueKey(
                                            'letter-learning-source-${letter.id}',
                                          ),
                                          data: letter,
                                          size: viewData.config.sourceCellSize,
                                          isEnabled: viewData.canGuess,
                                          onGuess: onGuess,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              RewardGemRow(count: viewData.score),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            if (viewData.state == LetterLearningState.won)
              Positioned.fill(
                child: GameEndOverlay(
                  message: 'Congratulations!',
                  onRestart: onRestart,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _Controls extends StatelessWidget {
  final Set<AlphabetDifficulty> difficulties;
  final LetterLearningMode mode;
  final ValueChanged<Set<AlphabetDifficulty>> onSetDifficulties;
  final ValueChanged<LetterLearningMode> onSetMode;

  const _Controls({
    required this.difficulties,
    required this.mode,
    required this.onSetDifficulties,
    required this.onSetMode,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 12,
    runSpacing: 10,
    children: [
      SegmentedButton<AlphabetDifficulty>(
        segments: [
          for (final difficulty in AlphabetDifficulty.values)
            ButtonSegment(
              value: difficulty,
              label: Text(_difficultyLabel(difficulty)),
            ),
        ],
        selected: difficulties,
        multiSelectionEnabled: true,
        emptySelectionAllowed: false,
        showSelectedIcon: false,
        onSelectionChanged: onSetDifficulties,
      ),
      SegmentedButton<LetterLearningMode>(
        segments: const [
          ButtonSegment(
            value: LetterLearningMode.masked,
            label: Text('Masked'),
          ),
          ButtonSegment(
            value: LetterLearningMode.unmasked,
            label: Text('Unmasked'),
          ),
        ],
        selected: {mode},
        showSelectedIcon: false,
        onSelectionChanged: (values) => onSetMode(values.single),
      ),
    ],
  );
}

String _difficultyLabel(AlphabetDifficulty difficulty) => switch (difficulty) {
  AlphabetDifficulty.beginner => 'Beginner',
  AlphabetDifficulty.intermediate => 'Intermediate',
  AlphabetDifficulty.advanced => 'Advanced',
};
