import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

import '../models/answer_feedback.dart';
import '../models/view_data.dart';
import '../models/sentence_quiz_state.dart';
import '../widgets/exercise_layout.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/game_end_overlay.dart';
import '../widgets/layered_person.dart';
import '../widgets/quiz_option_button.dart';
import '../widgets/reward_gem_row.dart';

class SentenceQuizScreen extends StatelessWidget {
  final SentenceQuizViewData viewData;
  final Future<void> Function(int) onSubmit;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  const SentenceQuizScreen({
    required this.viewData,
    required this.onSubmit,
    required this.onBack,
    required this.onRestart,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(
      title: context.l10n.activitySentenceQuiz,
      onBack: onBack,
    ),
    body: SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: _QuizContent(viewData: viewData, onSubmit: onSubmit),
          ),
          if (viewData.state == SentenceQuizState.won)
            Positioned.fill(
              child: GameEndOverlay(
                message: context.l10n.congratulations,
                onRestart: onRestart,
              ),
            ),
        ],
      ),
    ),
  );
}

class _QuizContent extends StatelessWidget {
  final SentenceQuizViewData viewData;
  final Future<void> Function(int) onSubmit;

  const _QuizContent({required this.viewData, required this.onSubmit});

  @override
  Widget build(BuildContext context) => ExerciseLayout(
    children: [
      LayeredPerson(
        shirtImagePath: viewData.question.visibleShirt.imagePath,
        jeansImagePath: viewData.question.visibleJeans.imagePath,
      ),
      for (var index = 0; index < viewData.question.options.length; index++)
        QuizOptionButton(
          key: ValueKey('sentence-option-$index'),
          label: viewData.question.options[index].text,
          feedback: viewData.correctHighlightIndex == index
              ? AnswerFeedback.correct
              : viewData.wrongHighlightIndex == index
              ? AnswerFeedback.wrong
              : AnswerFeedback.neutral,
          onPressed: viewData.canSubmit ? () => onSubmit(index) : null,
        ),
      RewardGemRow(count: viewData.score),
    ],
  );
}
