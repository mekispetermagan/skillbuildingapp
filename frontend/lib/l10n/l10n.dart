import 'package:flutter/widgets.dart';

import 'app_localizations.dart';
import '../models/activity_id.dart';

export 'app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

extension ActivityIdLocalization on ActivityId {
  String label(AppLocalizations l10n) => switch (this) {
    ActivityId.letterLearning => l10n.activityLetterLearning,
    ActivityId.letterPractice => l10n.activityLetterPractice,
    ActivityId.phraseBuilding => l10n.activityPhraseBuilding,
    ActivityId.letterDragging => l10n.activityLetterDragging,
    ActivityId.missingLetters => l10n.activityMissingLetters,
    ActivityId.letterShooting => l10n.activityLetterShooting,
    ActivityId.memoryCards => l10n.activityMemoryCards,
    ActivityId.letterCatching => l10n.activityLetterCatching,
    ActivityId.wordConveyor => l10n.activityWordConveyor,
    ActivityId.sentenceQuiz => l10n.activitySentenceQuiz,
    ActivityId.sentenceComposer => l10n.activitySentenceComposer,
    ActivityId.spellingQuiz => l10n.activitySpellingQuiz,
    ActivityId.crossword => l10n.activityCrossword,
    ActivityId.numberLearning => l10n.activityNumberLearning,
    ActivityId.numberComparison => l10n.activityNumberComparison,
    ActivityId.operatorConveyor => l10n.activityOperatorConveyor,
  };
}
