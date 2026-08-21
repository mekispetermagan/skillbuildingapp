import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

import '../models/letter_practice_state.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/feature_load_state.dart';
import '../widgets/game_end_overlay.dart';
import '../widgets/letter_practice_cards.dart';
import '../widgets/reward_gem_row.dart';

class LetterPracticeScreen extends StatelessWidget {
  final LetterPracticeViewData viewData;
  final VoidCallback onBack;
  final VoidCallback onRestart;
  final ValueChanged<Set<int>> onSetTiers;
  final ValueChanged<bool> onSetUseColors;
  final ValueChanged<String> onSelectLetter;
  final bool Function({required int slotId, required String letter}) canPlace;
  final Future<void> Function(int slotId) onPlaceSelected;
  final Future<void> Function({required int slotId, required String letter})
  onPlace;
  final Future<void> Function() onPlayAudio;

  const LetterPracticeScreen({
    required this.viewData,
    required this.onBack,
    required this.onRestart,
    required this.onSetTiers,
    required this.onSetUseColors,
    required this.onSelectLetter,
    required this.canPlace,
    required this.onPlaceSelected,
    required this.onPlace,
    required this.onPlayAudio,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(
      title: context.l10n.activityLetterPractice,
      onBack: onBack,
    ),
    body: FeatureLoadState(
      isLoading: viewData.isLoading,
      loadError: viewData.loadError,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: switch (viewData.currentWord) {
                final word? => CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList.list(
                        children: [
                          _Controls(
                            availableTiers: viewData.availableTiers,
                            tiers: viewData.tiers,
                            useColors: viewData.useColors,
                            onSetTiers: onSetTiers,
                            onSetUseColors: onSetUseColors,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 210,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned.fill(
                                  child: Image.asset(
                                    word.imagePath,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: IconButton.filled(
                                    onPressed: onPlayAudio,
                                    icon: const Icon(Icons.volume_up),
                                    iconSize: 32,
                                    tooltip: context.l10n.playWord,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              for (final slot in viewData.slots)
                                LetterPracticeTargetCard(
                                  key: ValueKey(
                                    'letter-practice-slot-${slot.id}',
                                  ),
                                  slot: slot,
                                  size: viewData.config.targetCellSize,
                                  useColors: viewData.useColors,
                                  isEnabled: viewData.canPlay,
                                  selectedLetter: viewData.selectedLetter,
                                  canPlace: canPlace,
                                  onPlaceSelected: onPlaceSelected,
                                  onPlace: onPlace,
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
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 4,
                                children: [
                                  for (final letter in viewData.sourceLetters)
                                    LetterPracticeSourceCard(
                                      key: ValueKey(
                                        'letter-practice-source-${letter.id}',
                                      ),
                                      data: letter,
                                      size: viewData.config.sourceCellSize,
                                      isSelected:
                                          viewData.selectedLetter ==
                                          letter.letter,
                                      isEnabled: viewData.canPlay,
                                      onSelect: onSelectLetter,
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
                null => const SizedBox.shrink(),
              },
            ),
            if (viewData.state == LetterPracticeState.won)
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

class _Controls extends StatelessWidget {
  final List<int> availableTiers;
  final Set<int> tiers;
  final bool useColors;
  final ValueChanged<Set<int>> onSetTiers;
  final ValueChanged<bool> onSetUseColors;

  const _Controls({
    required this.availableTiers,
    required this.tiers,
    required this.useColors,
    required this.onSetTiers,
    required this.onSetUseColors,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 12,
    runSpacing: 10,
    children: [
      SegmentedButton<int>(
        segments: [
          for (final tier in availableTiers)
            ButtonSegment(
              value: tier,
              label: Text(
                availableTiers.length > 3
                    ? '$tier'
                    : _tierLabel(context.l10n, tier),
              ),
            ),
        ],
        selected: tiers,
        multiSelectionEnabled: true,
        emptySelectionAllowed: false,
        showSelectedIcon: false,
        onSelectionChanged: onSetTiers,
      ),
      SegmentedButton<bool>(
        segments: [
          ButtonSegment(value: true, label: Text(context.l10n.colorsOn)),
          ButtonSegment(value: false, label: Text(context.l10n.colorsOff)),
        ],
        selected: {useColors},
        showSelectedIcon: false,
        onSelectionChanged: (values) => onSetUseColors(values.single),
      ),
    ],
  );
}

String _tierLabel(AppLocalizations l10n, int tier) => switch (tier) {
  1 => l10n.difficultyBeginner,
  2 => l10n.difficultyIntermediate,
  3 => l10n.difficultyAdvanced,
  _ => '$tier',
};
