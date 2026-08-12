import 'package:flutter/material.dart';

import '../models/answer_feedback.dart';
import '../models/spelling_quiz_state.dart';
import '../models/view_data.dart';
import '../widgets/exercise_layout.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/feature_load_state.dart';
import '../widgets/game_end_overlay.dart';
import '../widgets/quiz_option_button.dart';
import '../widgets/reward_gem_row.dart';

class SpellingQuizScreen extends StatelessWidget {
  final SpellingQuizViewData viewData;
  final Future<void> Function(int) onSubmit;
  final Future<void> Function() onPlayAudio;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  const SpellingQuizScreen({
    required this.viewData,
    required this.onSubmit,
    required this.onPlayAudio,
    required this.onBack,
    required this.onRestart,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(title: 'Spelling quiz', onBack: onBack),
    body: FeatureLoadState(
      isLoading: viewData.isLoading,
      errorMessage: viewData.errorMessage,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: switch (viewData.question) {
                final question? => ExerciseLayout(
                  children: [
                    SizedBox(
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              question.animal.imagePath,
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
                              tooltip: 'Play word',
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (
                      var index = 0;
                      index < question.options.length;
                      index++
                    )
                      QuizOptionButton(
                        key: ValueKey('spelling-option-$index'),
                        label: question.options[index],
                        feedback: viewData.correctHighlightIndex == index
                            ? AnswerFeedback.correct
                            : viewData.wrongHighlightIndex == index
                            ? AnswerFeedback.wrong
                            : AnswerFeedback.neutral,
                        onPressed: viewData.canSubmit
                            ? () => onSubmit(index)
                            : null,
                      ),
                    RewardGemRow(count: viewData.score),
                  ],
                ),
                null => const SizedBox.shrink(),
              },
            ),
            if (viewData.state == SpellingQuizState.won)
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
