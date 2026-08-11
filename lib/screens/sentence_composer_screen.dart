import 'package:flutter/material.dart';

import '../controllers/sentence_composer_controller.dart';
import '../models/sentence_quiz_sentence.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/layered_person.dart';
import '../widgets/rewards.dart';
import '../widgets/single_select_segments.dart';

class SentenceComposerScreen extends StatelessWidget {
  final SentenceComposerController controller;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  const SentenceComposerScreen({
    required this.controller,
    required this.onBack,
    required this.onRestart,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(title: 'Sentence composer', onBack: onBack),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: controller,
        builder: (_, _) => Stack(
          children: [
            Positioned.fill(child: _ComposerContent(controller: controller)),
            if (controller.state == SentenceComposerState.won)
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
    ),
  );
}

class _ComposerContent extends StatelessWidget {
  final SentenceComposerController controller;

  const _ComposerContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    final outfit = controller.outfit;
    final canSelect = controller.canSelect;
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
                  controller.composedSentence,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SingleSelectSegments<SentencePerson>(
                  choices: [
                    for (final person in SentencePerson.values)
                      SegmentChoice(
                        value: person,
                        label: person.displayName,
                        feedback: _feedback(controller.personFeedback(person)),
                      ),
                  ],
                  selected: controller.selectedPerson,
                  onSelected: canSelect ? controller.selectPerson : null,
                ),
                SingleSelectSegments<GarmentColor>(
                  choices: [
                    for (final color in GarmentColor.values)
                      SegmentChoice(
                        value: color,
                        label: color.name,
                        feedback: _feedback(controller.colorFeedback(color)),
                      ),
                  ],
                  selected: controller.selectedColor,
                  onSelected: canSelect ? controller.selectColor : null,
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
                        feedback: _feedback(controller.pieceFeedback(piece)),
                      ),
                  ],
                  selected: controller.selectedPiece,
                  onSelected: canSelect ? controller.selectPiece : null,
                ),
                Center(
                  child: FilledButton(
                    key: const ValueKey('sentence-composer-submit'),
                    onPressed: controller.canSubmit ? controller.submit : null,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      child: Text('Submit', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
                SizedBox(height: 46, child: Rewards(count: controller.score)),
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
