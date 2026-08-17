// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'Olvasós játék';

  @override
  String get activityLetterLearning => 'Betűtanuló';

  @override
  String get activityLetterPractice => 'Betűgyakorló';

  @override
  String get activityPhraseBuilding => 'Mondatkirakó';

  @override
  String get activityLetterDragging => 'Betűrendező';

  @override
  String get activityMissingLetters => 'Betűpótló';

  @override
  String get activityLetterShooting => 'Betűágyú';

  @override
  String get activityMemoryCards => 'Memóriakártyák';

  @override
  String get activityLetterCatching => 'Betűfogás';

  @override
  String get activityWordConveyor => 'Futószalagos';

  @override
  String get activitySentenceQuiz => 'Mondatos kvíz';

  @override
  String get activitySentenceComposer => 'Mondatépítő';

  @override
  String get activitySpellingQuiz => 'Helyesírás kvíz';

  @override
  String get activityCrossword => 'Keresztrejtvény';

  @override
  String get activityNumberLearning => 'Számtanulás';

  @override
  String get activityNumberComparison => 'Számok összehasonlítása';

  @override
  String get activityOperatorConveyor => 'Műveleti futószalag';

  @override
  String get numberPattern => 'Minta';

  @override
  String get numberScattered => 'Szórt';

  @override
  String get areaLiteracy => 'Írás és olvasás';

  @override
  String get areaMath => 'Matematika';

  @override
  String mathFeature(int number) {
    return '$number. funkció';
  }

  @override
  String get featureComingSoon => 'Hamarosan';

  @override
  String get congratulations => 'Gratulálok!';

  @override
  String get sorry => 'Sajna...';

  @override
  String get playAgain => 'Még egy játék?';

  @override
  String get rateActivity => 'Mennyire tetszett ez a játék?';

  @override
  String ratingStar(int rating) {
    return '$rating csillag az 5-ből';
  }

  @override
  String get check => 'Ellenőrzés';

  @override
  String get submit => 'Beküldés';

  @override
  String get pass => 'Passz';

  @override
  String get next => 'Következő';

  @override
  String get findBoth => 'Találd meg mindkettőt';

  @override
  String get playWord => 'Játszd le';

  @override
  String get playSentence => 'Játszd le';

  @override
  String get playLetterAndWord => 'Játszd le';

  @override
  String get instructionOrderLetters => 'Rakd sorrendbe a betűket!';

  @override
  String get instructionMissingLetters => 'Illeszd be a hiányzó betűket!';

  @override
  String get instructionCrossword =>
      'Válassz egy betűt, aztán egy üres helyet, vagy húzd oda a betűt!';

  @override
  String get memoryNotEnoughPairs => 'Nincs elég szó a játékhoz.';

  @override
  String get difficultyBeginner => 'Kezdő';

  @override
  String get difficultyIntermediate => 'Középhaladó';

  @override
  String get difficultyAdvanced => 'Haladó';

  @override
  String get colorsOn => 'Színek be';

  @override
  String get colorsOff => 'Színek ki';

  @override
  String get imagesOn => 'Képek be';

  @override
  String get imagesOff => 'Képek ki';

  @override
  String get masked => 'Takarva';

  @override
  String get unmasked => 'Felfedve';

  @override
  String letterDraggingResult(int score) {
    return 'Szép volt!\n$score drágakövet gyűjtöttél.';
  }

  @override
  String livesRemaining(int lives, int maximumLives) {
    return '$lives / $maximumLives életed maradt';
  }

  @override
  String get loadErrorPhraseBuilding =>
      'Nem sikerült betölteni a mondatos játékot.';

  @override
  String get loadErrorLetterDragging =>
      'Nem sikerült betölteni a betűrendező játékot.';

  @override
  String get loadErrorMissingLetters =>
      'Nem sikerült betölteni a betűpótló játékot.';

  @override
  String get loadErrorLetterShooting =>
      'Nem sikerült betölteni a betűágyú játékot.';

  @override
  String get loadErrorLetterCatching =>
      'Nem sikerült betölteni a betűfogó játékot.';

  @override
  String get loadErrorMemoryCards =>
      'Nem sikerült betölteni a memóriakártya játékot.';

  @override
  String get loadErrorWordConveyor =>
      'Nem sikerült betölteni a szó-futószalag játékot.';

  @override
  String get loadErrorSpellingQuiz =>
      'Nem sikerült betölteni a helyesírás-kvíz játékot.';

  @override
  String get loadErrorCrossword =>
      'Nem sikerült betölteni a keresztrejtvény játékot.';

  @override
  String get loadErrorLetterPractice =>
      'Nem sikerült betölteni a betűgyakorló játékot.';

  @override
  String get loadErrorLetterLearning =>
      'Nem sikerült betölteni a betűtanuló játékot.';
}
