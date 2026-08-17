// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Lesespiel';

  @override
  String get activityLetterLearning => 'Buchstaben lernen';

  @override
  String get activityLetterPractice => 'Buchstaben üben';

  @override
  String get activityPhraseBuilding => 'Sätze bauen';

  @override
  String get activityLetterDragging => 'Buchstaben ordnen';

  @override
  String get activityMissingLetters => 'Fehlende Buchstaben';

  @override
  String get activityLetterShooting => 'Buchstaben schießen';

  @override
  String get activityMemoryCards => 'Memorykarten';

  @override
  String get activityLetterCatching => 'Buchstaben fangen';

  @override
  String get activityWordConveyor => 'Wortförderband';

  @override
  String get activitySentenceQuiz => 'Satzquiz';

  @override
  String get activitySentenceComposer => 'Satz zusammenstellen';

  @override
  String get activitySpellingQuiz => 'Rechtschreibquiz';

  @override
  String get activityCrossword => 'Kreuzworträtsel';

  @override
  String get activityNumberLearning => 'Zahlen lernen';

  @override
  String get activityNumberComparison => 'Zahlen vergleichen';

  @override
  String get activityOperationsPractice => 'Rechenübungen';

  @override
  String get activityOperatorConveyor => 'Rechenzeichen-Förderband';

  @override
  String get activityEvenOdd => 'Gerade oder ungerade';

  @override
  String get numberPattern => 'Muster';

  @override
  String get numberScattered => 'Verstreut';

  @override
  String get areaLiteracy => 'Lesen und Schreiben';

  @override
  String get areaMath => 'Mathematik';

  @override
  String mathFeature(int number) {
    return 'Funktion $number';
  }

  @override
  String get featureComingSoon => 'Demnächst verfügbar';

  @override
  String get congratulations => 'Herzlichen Glückwunsch!';

  @override
  String get sorry => 'Schade!';

  @override
  String get playAgain => 'Noch einmal spielen?';

  @override
  String get rateActivity => 'Wie gut hat dir dieses Spiel gefallen?';

  @override
  String ratingStar(int rating) {
    return '$rating von 5 Sternen';
  }

  @override
  String get check => 'Prüfen';

  @override
  String get submit => 'Absenden';

  @override
  String get pass => 'Überspringen';

  @override
  String get next => 'Weiter';

  @override
  String get findBoth => 'Finde beide';

  @override
  String get playWord => 'Wort abspielen';

  @override
  String get playSentence => 'Satz abspielen';

  @override
  String get playLetterAndWord => 'Buchstaben und Wort abspielen';

  @override
  String get instructionOrderLetters =>
      'Bringe die Buchstaben in die richtige Reihenfolge';

  @override
  String get instructionMissingLetters =>
      'Setze die fehlenden Buchstaben in das Wort ein';

  @override
  String get instructionCrossword =>
      'Wähle einen Buchstaben aus und setze ihn in ein leeres Feld oder ziehe ihn dorthin';

  @override
  String get memoryNotEnoughPairs => 'Es gibt nicht genügend Wort-Bild-Paare.';

  @override
  String get difficultyBeginner => 'Anfänger';

  @override
  String get difficultyIntermediate => 'Mittel';

  @override
  String get difficultyAdvanced => 'Fortgeschritten';

  @override
  String get difficultyEasy => 'Leicht';

  @override
  String get difficultyHard => 'Schwer';

  @override
  String get colorsOn => 'Farben an';

  @override
  String get colorsOff => 'Farben aus';

  @override
  String get imagesOn => 'Bilder an';

  @override
  String get imagesOff => 'Bilder aus';

  @override
  String get masked => 'Verdeckt';

  @override
  String get unmasked => 'Sichtbar';

  @override
  String letterDraggingResult(int score) {
    return 'Gut gemacht!\nDu hast $score Edelsteine gesammelt.';
  }

  @override
  String livesRemaining(int lives, int maximumLives) {
    return 'Noch $lives von $maximumLives Leben übrig';
  }

  @override
  String get loadErrorPhraseBuilding =>
      'Die Satzbau-Aktivität konnte nicht geladen werden.';

  @override
  String get loadErrorLetterDragging =>
      'Die Buchstabenordnungs-Aktivität konnte nicht geladen werden.';

  @override
  String get loadErrorMissingLetters =>
      'Die Aktivität mit fehlenden Buchstaben konnte nicht geladen werden.';

  @override
  String get loadErrorLetterShooting =>
      'Die Buchstabenschieß-Aktivität konnte nicht geladen werden.';

  @override
  String get loadErrorLetterCatching =>
      'Die Buchstabenfang-Aktivität konnte nicht geladen werden.';

  @override
  String get loadErrorMemoryCards =>
      'Die Memorykarten-Aktivität konnte nicht geladen werden.';

  @override
  String get loadErrorWordConveyor =>
      'Die Wortförderband-Aktivität konnte nicht geladen werden.';

  @override
  String get loadErrorSpellingQuiz =>
      'Das Rechtschreibquiz konnte nicht geladen werden.';

  @override
  String get loadErrorCrossword =>
      'Das Kreuzworträtsel konnte nicht geladen werden.';

  @override
  String get loadErrorLetterPractice =>
      'Die Buchstabenübungs-Aktivität konnte nicht geladen werden.';

  @override
  String get loadErrorLetterLearning =>
      'Die Buchstabenlern-Aktivität konnte nicht geladen werden.';
}
