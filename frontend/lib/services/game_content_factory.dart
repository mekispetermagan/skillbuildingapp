import '../models/activity_id.dart';
import '../models/alphabet_letter.dart';
import '../models/alphabet_object.dart';
import '../models/image_word.dart';
import '../models/interface_language.dart';

class GameContentFactory {
  const GameContentFactory();

  String get letterPracticeAlphabetPath =>
      'assets/data/alphabet_progression.json';
  String get letterLearningAlphabetPath =>
      'assets/data/alphabet_progression.json';

  List<ImageWord> letterPracticeWords({
    required List<ImageWord> englishWords,
    required List<AlphabetLetter> alphabet,
  }) => englishWords;

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
  List<ImageWord> letterPracticeWords({
    required List<ImageWord> englishWords,
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
          activity == ActivityId.letterLearning
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
