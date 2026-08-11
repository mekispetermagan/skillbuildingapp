import 'package:flutter/material.dart';

import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/layered_person.dart';
import '../widgets/rewards.dart';

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
    appBar: FeatureAppBar(title: 'Sentence quiz', onBack: onBack),
    body: SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: _QuizContent(viewData: viewData, onSubmit: onSubmit),
          ),
          if (viewData.state == SentenceQuizState.won)
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

class _QuizContent extends StatelessWidget {
  final SentenceQuizViewData viewData;
  final Future<void> Function(int) onSubmit;

  const _QuizContent({required this.viewData, required this.onSubmit});

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
                shirtImagePath: viewData.question.visibleShirt.imagePath,
                jeansImagePath: viewData.question.visibleJeans.imagePath,
              ),
              for (
                var index = 0;
                index < viewData.question.options.length;
                index++
              )
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: FilledButton(
                    key: ValueKey('sentence-option-$index'),
                    onPressed: viewData.canSubmit
                        ? () => onSubmit(index)
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
                        viewData.question.options[index].text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                      ),
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

  Color _buttonBackground(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    if (viewData.correctHighlightIndex == index) {
      return ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: scheme.brightness,
      ).primaryContainer;
    }
    if (viewData.wrongHighlightIndex == index) return scheme.errorContainer;
    return scheme.primaryContainer;
  }

  Color _buttonForeground(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    if (viewData.correctHighlightIndex == index) {
      return ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: scheme.brightness,
      ).onPrimaryContainer;
    }
    if (viewData.wrongHighlightIndex == index) {
      return scheme.onErrorContainer;
    }
    return scheme.onPrimaryContainer;
  }
}
