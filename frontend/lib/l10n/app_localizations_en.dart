// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Literacy Game';

  @override
  String get start => 'Start';

  @override
  String get activityLetterLearning => 'Letter learning';

  @override
  String get activityLetterPractice => 'Letter practice';

  @override
  String get activityPhraseBuilding => 'Sentence building';

  @override
  String get activityLetterDragging => 'Letter dragging';

  @override
  String get activityMissingLetters => 'Missing letters';

  @override
  String get activityLetterShooting => 'Letter shooting';

  @override
  String get activityMemoryCards => 'Memory cards';

  @override
  String get activityLetterCatching => 'Letter catching';

  @override
  String get activityWordConveyor => 'Word conveyor';

  @override
  String get activitySentenceQuiz => 'Sentence quiz';

  @override
  String get activitySentenceComposer => 'Sentence composer';

  @override
  String get activitySpellingQuiz => 'Spelling quiz';

  @override
  String get activityCrossword => 'Crossword';

  @override
  String get activityNumberLearning => 'Number learning';

  @override
  String get activityNumberComparison => 'Compare numbers';

  @override
  String get activityOperationsPractice => 'Operations practice';

  @override
  String get activityNumberDragging => 'Number dragging';

  @override
  String get activityNumberMemory => 'Number memory';

  @override
  String get activityBalanceGame => 'Balance game';

  @override
  String get activityLogicGame => 'Logic game';

  @override
  String get activityShoppingGame => 'Shopping game';

  @override
  String get notEnough => 'Not enough!';

  @override
  String get takeTheBalance => 'Take the balance!';

  @override
  String get activityOperatorConveyor => 'Operator conveyor';

  @override
  String get activityEvenOdd => 'Even or odd';

  @override
  String get numberPattern => 'Pattern';

  @override
  String get numberScattered => 'Scattered';

  @override
  String get areaLiteracy => 'Literacy';

  @override
  String get areaMath => 'Math';

  @override
  String mathFeature(int number) {
    return 'Feature $number';
  }

  @override
  String get featureComingSoon => 'Coming soon';

  @override
  String get congratulations => 'Congratulations!';

  @override
  String get sorry => 'Sorry!';

  @override
  String get playAgain => 'Play again';

  @override
  String get rateActivity => 'How much did you like this game?';

  @override
  String ratingStar(int rating) {
    return '$rating out of 5 stars';
  }

  @override
  String get check => 'Check';

  @override
  String get submit => 'Submit';

  @override
  String get pass => 'Pass';

  @override
  String get next => 'Next';

  @override
  String get findBoth => 'Find both';

  @override
  String get playWord => 'Play word';

  @override
  String get playSentence => 'Play sentence';

  @override
  String get playLetterAndWord => 'Play letter and word';

  @override
  String get instructionOrderLetters => 'Put the letters in the right order';

  @override
  String get instructionOrderNumbers =>
      'Put the numbers from smallest to largest';

  @override
  String get instructionMissingLetters =>
      'Drag the missing letters into the word';

  @override
  String get instructionCrossword =>
      'Choose or drag a letter into an empty square';

  @override
  String get memoryNotEnoughPairs => 'Not enough word and image pairs.';

  @override
  String get difficultyBeginner => 'Beginner';

  @override
  String get difficultyIntermediate => 'Intermediate';

  @override
  String get difficultyAdvanced => 'Advanced';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get colorsOn => 'Colors on';

  @override
  String get colorsOff => 'Colors off';

  @override
  String get imagesOn => 'Images on';

  @override
  String get imagesOff => 'Images off';

  @override
  String get masked => 'Masked';

  @override
  String get unmasked => 'Unmasked';

  @override
  String letterDraggingResult(int score) {
    return 'Great work!\nYou collected $score gems.';
  }

  @override
  String numberDraggingResult(int score) {
    return 'Great work!\nYou collected $score gems.';
  }

  @override
  String livesRemaining(int lives, int maximumLives) {
    return '$lives of $maximumLives lives remaining';
  }

  @override
  String get loadErrorPhraseBuilding => 'Could not load the sentence activity.';

  @override
  String get loadErrorLetterDragging =>
      'Could not load the letter-dragging activity.';

  @override
  String get loadErrorMissingLetters =>
      'Could not load the missing-letters activity.';

  @override
  String get loadErrorLetterShooting =>
      'Could not load the letter-shooting activity.';

  @override
  String get loadErrorLetterCatching =>
      'Could not load the letter-catching activity.';

  @override
  String get loadErrorMemoryCards => 'Could not load the memory-card activity.';

  @override
  String get loadErrorWordConveyor =>
      'Could not load the word-conveyor activity.';

  @override
  String get loadErrorSpellingQuiz =>
      'Could not load the spelling-quiz activity.';

  @override
  String get loadErrorCrossword => 'Could not load the crossword activity.';

  @override
  String get loadErrorLetterPractice =>
      'Could not load the letter-practice activity.';

  @override
  String get loadErrorLetterLearning =>
      'Could not load the letter-learning activity.';
}
