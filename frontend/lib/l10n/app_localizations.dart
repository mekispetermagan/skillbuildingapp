import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('hu'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Literacy Game'**
  String get appTitle;

  /// No description provided for @activityLetterLearning.
  ///
  /// In en, this message translates to:
  /// **'Letter learning'**
  String get activityLetterLearning;

  /// No description provided for @activityLetterPractice.
  ///
  /// In en, this message translates to:
  /// **'Letter practice'**
  String get activityLetterPractice;

  /// No description provided for @activityPhraseBuilding.
  ///
  /// In en, this message translates to:
  /// **'Sentence building'**
  String get activityPhraseBuilding;

  /// No description provided for @activityLetterDragging.
  ///
  /// In en, this message translates to:
  /// **'Letter dragging'**
  String get activityLetterDragging;

  /// No description provided for @activityMissingLetters.
  ///
  /// In en, this message translates to:
  /// **'Missing letters'**
  String get activityMissingLetters;

  /// No description provided for @activityLetterShooting.
  ///
  /// In en, this message translates to:
  /// **'Letter shooting'**
  String get activityLetterShooting;

  /// No description provided for @activityMemoryCards.
  ///
  /// In en, this message translates to:
  /// **'Memory cards'**
  String get activityMemoryCards;

  /// No description provided for @activityLetterCatching.
  ///
  /// In en, this message translates to:
  /// **'Letter catching'**
  String get activityLetterCatching;

  /// No description provided for @activityWordConveyor.
  ///
  /// In en, this message translates to:
  /// **'Word conveyor'**
  String get activityWordConveyor;

  /// No description provided for @activitySentenceQuiz.
  ///
  /// In en, this message translates to:
  /// **'Sentence quiz'**
  String get activitySentenceQuiz;

  /// No description provided for @activitySentenceComposer.
  ///
  /// In en, this message translates to:
  /// **'Sentence composer'**
  String get activitySentenceComposer;

  /// No description provided for @activitySpellingQuiz.
  ///
  /// In en, this message translates to:
  /// **'Spelling quiz'**
  String get activitySpellingQuiz;

  /// No description provided for @activityCrossword.
  ///
  /// In en, this message translates to:
  /// **'Crossword'**
  String get activityCrossword;

  /// No description provided for @activityNumberLearning.
  ///
  /// In en, this message translates to:
  /// **'Number learning'**
  String get activityNumberLearning;

  /// No description provided for @activityNumberComparison.
  ///
  /// In en, this message translates to:
  /// **'Compare numbers'**
  String get activityNumberComparison;

  /// No description provided for @activityOperatorConveyor.
  ///
  /// In en, this message translates to:
  /// **'Operator conveyor'**
  String get activityOperatorConveyor;

  /// No description provided for @numberPattern.
  ///
  /// In en, this message translates to:
  /// **'Pattern'**
  String get numberPattern;

  /// No description provided for @numberScattered.
  ///
  /// In en, this message translates to:
  /// **'Scattered'**
  String get numberScattered;

  /// No description provided for @areaLiteracy.
  ///
  /// In en, this message translates to:
  /// **'Literacy'**
  String get areaLiteracy;

  /// No description provided for @areaMath.
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get areaMath;

  /// No description provided for @mathFeature.
  ///
  /// In en, this message translates to:
  /// **'Feature {number}'**
  String mathFeature(int number);

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get featureComingSoon;

  /// No description provided for @congratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get congratulations;

  /// No description provided for @sorry.
  ///
  /// In en, this message translates to:
  /// **'Sorry!'**
  String get sorry;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// No description provided for @rateActivity.
  ///
  /// In en, this message translates to:
  /// **'How much did you like this game?'**
  String get rateActivity;

  /// No description provided for @ratingStar.
  ///
  /// In en, this message translates to:
  /// **'{rating} out of 5 stars'**
  String ratingStar(int rating);

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @pass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get pass;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @findBoth.
  ///
  /// In en, this message translates to:
  /// **'Find both'**
  String get findBoth;

  /// No description provided for @playWord.
  ///
  /// In en, this message translates to:
  /// **'Play word'**
  String get playWord;

  /// No description provided for @playSentence.
  ///
  /// In en, this message translates to:
  /// **'Play sentence'**
  String get playSentence;

  /// No description provided for @playLetterAndWord.
  ///
  /// In en, this message translates to:
  /// **'Play letter and word'**
  String get playLetterAndWord;

  /// No description provided for @instructionOrderLetters.
  ///
  /// In en, this message translates to:
  /// **'Put the letters in the right order'**
  String get instructionOrderLetters;

  /// No description provided for @instructionMissingLetters.
  ///
  /// In en, this message translates to:
  /// **'Drag the missing letters into the word'**
  String get instructionMissingLetters;

  /// No description provided for @instructionCrossword.
  ///
  /// In en, this message translates to:
  /// **'Choose or drag a letter into an empty square'**
  String get instructionCrossword;

  /// No description provided for @memoryNotEnoughPairs.
  ///
  /// In en, this message translates to:
  /// **'Not enough word and image pairs.'**
  String get memoryNotEnoughPairs;

  /// No description provided for @difficultyBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get difficultyBeginner;

  /// No description provided for @difficultyIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get difficultyIntermediate;

  /// No description provided for @difficultyAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get difficultyAdvanced;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @colorsOn.
  ///
  /// In en, this message translates to:
  /// **'Colors on'**
  String get colorsOn;

  /// No description provided for @colorsOff.
  ///
  /// In en, this message translates to:
  /// **'Colors off'**
  String get colorsOff;

  /// No description provided for @imagesOn.
  ///
  /// In en, this message translates to:
  /// **'Images on'**
  String get imagesOn;

  /// No description provided for @imagesOff.
  ///
  /// In en, this message translates to:
  /// **'Images off'**
  String get imagesOff;

  /// No description provided for @masked.
  ///
  /// In en, this message translates to:
  /// **'Masked'**
  String get masked;

  /// No description provided for @unmasked.
  ///
  /// In en, this message translates to:
  /// **'Unmasked'**
  String get unmasked;

  /// No description provided for @letterDraggingResult.
  ///
  /// In en, this message translates to:
  /// **'Great work!\nYou collected {score} gems.'**
  String letterDraggingResult(int score);

  /// No description provided for @livesRemaining.
  ///
  /// In en, this message translates to:
  /// **'{lives} of {maximumLives} lives remaining'**
  String livesRemaining(int lives, int maximumLives);

  /// No description provided for @loadErrorPhraseBuilding.
  ///
  /// In en, this message translates to:
  /// **'Could not load the sentence activity.'**
  String get loadErrorPhraseBuilding;

  /// No description provided for @loadErrorLetterDragging.
  ///
  /// In en, this message translates to:
  /// **'Could not load the letter-dragging activity.'**
  String get loadErrorLetterDragging;

  /// No description provided for @loadErrorMissingLetters.
  ///
  /// In en, this message translates to:
  /// **'Could not load the missing-letters activity.'**
  String get loadErrorMissingLetters;

  /// No description provided for @loadErrorLetterShooting.
  ///
  /// In en, this message translates to:
  /// **'Could not load the letter-shooting activity.'**
  String get loadErrorLetterShooting;

  /// No description provided for @loadErrorLetterCatching.
  ///
  /// In en, this message translates to:
  /// **'Could not load the letter-catching activity.'**
  String get loadErrorLetterCatching;

  /// No description provided for @loadErrorMemoryCards.
  ///
  /// In en, this message translates to:
  /// **'Could not load the memory-card activity.'**
  String get loadErrorMemoryCards;

  /// No description provided for @loadErrorWordConveyor.
  ///
  /// In en, this message translates to:
  /// **'Could not load the word-conveyor activity.'**
  String get loadErrorWordConveyor;

  /// No description provided for @loadErrorSpellingQuiz.
  ///
  /// In en, this message translates to:
  /// **'Could not load the spelling-quiz activity.'**
  String get loadErrorSpellingQuiz;

  /// No description provided for @loadErrorCrossword.
  ///
  /// In en, this message translates to:
  /// **'Could not load the crossword activity.'**
  String get loadErrorCrossword;

  /// No description provided for @loadErrorLetterPractice.
  ///
  /// In en, this message translates to:
  /// **'Could not load the letter-practice activity.'**
  String get loadErrorLetterPractice;

  /// No description provided for @loadErrorLetterLearning.
  ///
  /// In en, this message translates to:
  /// **'Could not load the letter-learning activity.'**
  String get loadErrorLetterLearning;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'hu':
      return AppLocalizationsHu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
