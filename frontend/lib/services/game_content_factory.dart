import '../models/activity_id.dart';
import '../models/alphabet_letter.dart';
import '../models/alphabet_object.dart';
import '../models/image_word.dart';
import '../models/interface_language.dart';
import '../models/math_notation.dart';
import '../models/sentence_content.dart';
import '../models/shopping_game.dart';

class GameContentFactory {
  const GameContentFactory();

  String get letterPracticeAlphabetPath =>
      'assets/data/alphabet_progression.json';
  String get letterLearningAlphabetPath =>
      'assets/data/alphabet_progression.json';
  String get localizedAnimalWordsPath => 'assets/data/animal_image_words.json';
  String get phraseBuildingSentencesPath => 'assets/data/sentences_en.json';
  String get letterShootingWordsPath =>
      'assets/data/letter_shooting_words.json';
  String get crosswordWordsPath => 'assets/data/crossword_words.json';
  List<String> get letterShootingVowels => const ['A', 'E', 'I', 'O', 'U'];
  SentenceContent get sentenceContent => englishSentenceContent;
  MathNotation get mathNotation => westernMathNotation;
  ShoppingGameConfig get shoppingGameConfig => const ShoppingGameConfig();

  List<ImageWord> letterPracticeAlphabetWords({
    required List<AlphabetObject> englishObjects,
    required List<AlphabetLetter> alphabet,
  }) => [
    for (final object in englishObjects)
      ImageWord(
        id: object.id,
        word: object.word,
        imagePath: object.imagePath,
        audioPath: object.audioPath,
      ),
  ];

  List<AlphabetObject> letterLearningObjects({
    required List<AlphabetObject> englishObjects,
    required List<AlphabetLetter> alphabet,
  }) => englishObjects;

  String contentVersionFor(ActivityId activity, String fallback) => fallback;

  factory GameContentFactory.forLanguage(InterfaceLanguage language) =>
      switch (language) {
        InterfaceLanguage.hungarian => const HungarianGameContentFactory(),
        _ => const GameContentFactory(),
      };
}

class HungarianGameContentFactory extends GameContentFactory {
  const HungarianGameContentFactory();

  @override
  String get letterPracticeAlphabetPath =>
      'assets/data/alphabet_progression_hu.json';

  @override
  String get letterLearningAlphabetPath =>
      'assets/data/alphabet_progression_hu.json';
  @override
  String get localizedAnimalWordsPath =>
      'assets/data/animal_image_words_hu.json';
  @override
  String get phraseBuildingSentencesPath => 'assets/data/sentences_hu.json';
  @override
  String get letterShootingWordsPath =>
      'assets/data/letter_shooting_words_hu.json';
  @override
  String get crosswordWordsPath => 'assets/data/crossword_words_hu.json';
  @override
  List<String> get letterShootingVowels => const ['A', 'E', 'É', 'Ő', 'I', 'Á'];
  @override
  SentenceContent get sentenceContent => hungarianSentenceContent;
  @override
  MathNotation get mathNotation => hungarianMathNotation;
  @override
  ShoppingGameConfig get shoppingGameConfig => hungarianShoppingGameConfig;

  @override
  List<ImageWord> letterPracticeAlphabetWords({
    required List<AlphabetObject> englishObjects,
    required List<AlphabetLetter> alphabet,
  }) => [
    for (final letter in alphabet)
      if (letter.objectWord case final word?)
        ImageWord(
          id: letter.id,
          word: word,
          imagePath:
              'assets/images/alphabet_objects_hu/${_hungarianWordStem(word)}.png',
          audioPath: letter.audioPath,
        ),
  ];

  @override
  List<AlphabetObject> letterLearningObjects({
    required List<AlphabetObject> englishObjects,
    required List<AlphabetLetter> alphabet,
  }) => [
    for (final letter in alphabet)
      if (letter.objectWord case final word?)
        AlphabetObject(
          id: letter.id,
          letter: letter.letter,
          word: word,
          imagePath:
              'assets/images/alphabet_objects_hu/${_hungarianWordStem(word)}.png',
          audioPath: letter.audioPath,
        ),
  ];

  @override
  String contentVersionFor(ActivityId activity, String fallback) =>
      activity == ActivityId.letterPractice ||
          activity == ActivityId.letterLearning ||
          activity == ActivityId.letterDragging ||
          activity == ActivityId.missingLetters ||
          activity == ActivityId.memoryCards ||
          activity == ActivityId.wordConveyor ||
          activity == ActivityId.spellingQuiz ||
          activity == ActivityId.sentenceQuiz ||
          activity == ActivityId.sentenceComposer ||
          activity == ActivityId.letterCatching ||
          activity == ActivityId.phraseBuilding ||
          activity == ActivityId.letterShooting ||
          activity == ActivityId.crossword ||
          activity == ActivityId.shoppingGame
      ? 'hu-1'
      : fallback;

  String _hungarianWordStem(String word) {
    var value = word.replaceAll('[', '').replaceAll(']', '').toLowerCase();
    const replacements = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ö': 'o',
      'ő': 'o',
      'ú': 'u',
      'ü': 'u',
      'ű': 'u',
      ' ': '_',
    };
    for (final entry in replacements.entries) {
      value = value.replaceAll(entry.key, entry.value);
    }
    return value;
  }
}
