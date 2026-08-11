import 'package:flutter/material.dart';

import '../controllers/sentence_quiz_controller.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/layered_person.dart';
import '../widgets/rewards.dart';

class SentenceQuizScreen extends StatelessWidget {
  final SentenceQuizController controller;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  const SentenceQuizScreen({
    required this.controller,
    required this.onBack,
    required this.onRestart,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(title: 'Sentence quiz', onBack: onBack),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: controller,
        builder: (_, _) => Stack(
          children: [
            Positioned.fill(child: _QuizContent(controller: controller)),
            if (controller.state == SentenceQuizState.won)
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

class _QuizContent extends StatelessWidget {
  final SentenceQuizController controller;

  const _QuizContent({required this.controller});

  @override
  Widget build(BuildContext context) => CustomScrollView(
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
                shirtImagePath: controller.question.visibleShirt.imagePath,
                jeansImagePath: controller.question.visibleJeans.imagePath,
              ),
              for (
                var index = 0;
                index < controller.question.options.length;
                index++
              )
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: FilledButton(
                    key: ValueKey('sentence-option-$index'),
                    onPressed: controller.canSubmit
                        ? () => controller.submit(index)
                        : null,
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        _buttonBackground(context, index),
                      ),
                      foregroundColor: WidgetStatePropertyAll(
                        _buttonForeground(context, index),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        controller.question.options[index].text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                      ),
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

  Color _buttonBackground(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    if (controller.correctHighlightIndex == index) {
      return ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: scheme.brightness,
      ).primaryContainer;
    }
    if (controller.wrongHighlightIndex == index) return scheme.errorContainer;
    return scheme.primaryContainer;
  }

  Color _buttonForeground(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    if (controller.correctHighlightIndex == index) {
      return ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: scheme.brightness,
      ).onPrimaryContainer;
    }
    if (controller.wrongHighlightIndex == index) {
      return scheme.onErrorContainer;
    }
    return scheme.onPrimaryContainer;
  }
}
