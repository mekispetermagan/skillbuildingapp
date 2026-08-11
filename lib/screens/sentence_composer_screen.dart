import 'package:flutter/material.dart';

import '../models/sentence_quiz_sentence.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/layered_person.dart';
import '../widgets/rewards.dart';
import '../widgets/single_select_segments.dart';

class SentenceComposerScreen extends StatelessWidget {
  final SentenceComposerViewData viewData;
  final ValueChanged<SentencePerson> onSelectPerson;
  final ValueChanged<GarmentColor> onSelectColor;
  final ValueChanged<ClothingPiece> onSelectPiece;
  final Future<void> Function() onSubmit;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  const SentenceComposerScreen({
    required this.viewData,
    required this.onSelectPerson,
    required this.onSelectColor,
    required this.onSelectPiece,
    required this.onSubmit,
    required this.onBack,
    required this.onRestart,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(title: 'Sentence composer', onBack: onBack),
    body: SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: _ComposerContent(
              viewData: viewData,
              onSelectPerson: onSelectPerson,
              onSelectColor: onSelectColor,
              onSelectPiece: onSelectPiece,
              onSubmit: onSubmit,
            ),
          ),
          if (viewData.state == SentenceComposerState.won)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Congratulations!',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: onRestart,
                        child: const Text('Play again?'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _ComposerContent extends StatelessWidget {
  final SentenceComposerViewData viewData;
  final ValueChanged<SentencePerson> onSelectPerson;
  final ValueChanged<GarmentColor> onSelectColor;
  final ValueChanged<ClothingPiece> onSelectPiece;
  final Future<void> Function() onSubmit;

  const _ComposerContent({
    required this.viewData,
    required this.onSelectPerson,
    required this.onSelectColor,
    required this.onSelectPiece,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final outfit = viewData.outfit;
    final canSelect = viewData.canSelect;
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayeredPerson(
                  shirtImagePath: outfit.visibleShirt.imagePath,
                  jeansImagePath: outfit.visibleJeans.imagePath,
                ),
                Text(
                  viewData.composedSentence,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SingleSelectSegments<SentencePerson>(
                  choices: [
                    for (final person in SentencePerson.values)
                      SegmentChoice(
                        value: person,
                        label: person.displayName,
                        feedback: _feedback(viewData.personFeedback[person]!),
                      ),
                  ],
                  selected: viewData.selectedPerson,
                  onSelected: canSelect ? onSelectPerson : null,
                ),
                SingleSelectSegments<GarmentColor>(
                  choices: [
                    for (final color in GarmentColor.values)
                      SegmentChoice(
                        value: color,
                        label: color.name,
                        feedback: _feedback(viewData.colorFeedback[color]!),
                      ),
                  ],
                  selected: viewData.selectedColor,
                  onSelected: canSelect ? onSelectColor : null,
                ),
                SingleSelectSegments<ClothingPiece>(
                  choices: [
                    for (final piece in const [
                      ClothingPiece.jeans,
                      ClothingPiece.shirt,
                    ])
                      SegmentChoice(
                        value: piece,
                        label: piece.name,
                        feedback: _feedback(viewData.pieceFeedback[piece]!),
                      ),
                  ],
                  selected: viewData.selectedPiece,
                  onSelected: canSelect ? onSelectPiece : null,
                ),
                Center(
                  child: FilledButton(
                    key: const ValueKey('sentence-composer-submit'),
                    onPressed: viewData.canSubmit ? onSubmit : null,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      child: Text('Submit', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
                SizedBox(height: 46, child: Rewards(count: viewData.score)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  SegmentFeedback _feedback(ComposerChoiceFeedback feedback) =>
      switch (feedback) {
        ComposerChoiceFeedback.neutral => SegmentFeedback.neutral,
        ComposerChoiceFeedback.correct => SegmentFeedback.correct,
        ComposerChoiceFeedback.wrong => SegmentFeedback.wrong,
      };
}
