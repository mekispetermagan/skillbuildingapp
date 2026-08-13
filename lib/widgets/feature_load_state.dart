import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/feature_load_error.dart';

class FeatureLoadState extends StatelessWidget {
  final bool isLoading;
  final FeatureLoadError? loadError;
  final Widget child;

  const FeatureLoadState({
    required this.isLoading,
    required this.loadError,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (loadError case final error?) {
      return Center(child: Text(_message(context.l10n, error)));
    }
    return child;
  }
}

String _message(AppLocalizations l10n, FeatureLoadError error) =>
    switch (error) {
      FeatureLoadError.phraseBuilding => l10n.loadErrorPhraseBuilding,
      FeatureLoadError.letterDragging => l10n.loadErrorLetterDragging,
      FeatureLoadError.missingLetters => l10n.loadErrorMissingLetters,
      FeatureLoadError.letterShooting => l10n.loadErrorLetterShooting,
      FeatureLoadError.letterCatching => l10n.loadErrorLetterCatching,
      FeatureLoadError.memoryCards => l10n.loadErrorMemoryCards,
      FeatureLoadError.wordConveyor => l10n.loadErrorWordConveyor,
      FeatureLoadError.spellingQuiz => l10n.loadErrorSpellingQuiz,
      FeatureLoadError.crossword => l10n.loadErrorCrossword,
      FeatureLoadError.letterPractice => l10n.loadErrorLetterPractice,
      FeatureLoadError.letterLearning => l10n.loadErrorLetterLearning,
    };
