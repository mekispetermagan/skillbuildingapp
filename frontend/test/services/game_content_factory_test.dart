import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/models/activity_id.dart';
import 'package:skillbuilding_game/models/alphabet_letter.dart';
import 'package:skillbuilding_game/models/image_word.dart';
import 'package:skillbuilding_game/models/interface_language.dart';
import 'package:skillbuilding_game/models/letter_shooting_word.dart';
import 'package:skillbuilding_game/models/sentence.dart';
import 'package:skillbuilding_game/services/game_content_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Hungarian letter games use all localized object assets', () async {
    final encoded = await rootBundle.loadString(
      'assets/data/alphabet_progression_hu.json',
    );
    final data = jsonDecode(encoded) as List<dynamic>;
    final alphabet = [
      for (final item in data)
        AlphabetLetter.fromJson(item as Map<String, dynamic>),
    ];
    final factory = GameContentFactory.forLanguage(InterfaceLanguage.hungarian);

    final words = factory.letterPracticeAlphabetWords(
      englishObjects: const [],
      alphabet: alphabet,
    );
    final animalData =
        jsonDecode(
              await rootBundle.loadString(factory.localizedAnimalWordsPath),
            )
            as List<dynamic>;
    final animalWords = [
      for (final item in animalData)
        ImageWord.fromJson(item as Map<String, dynamic>),
    ];
    final objects = factory.letterLearningObjects(
      englishObjects: const [],
      alphabet: alphabet,
    );
    final sentenceData =
        jsonDecode(
              await rootBundle.loadString(factory.phraseBuildingSentencesPath),
            )
            as List<dynamic>;
    final sentences = [
      for (final item in sentenceData)
        Sentence.fromJson(item as Map<String, dynamic>),
    ];
    final shootingData =
        jsonDecode(await rootBundle.loadString(factory.letterShootingWordsPath))
            as List<dynamic>;
    final shootingWords = [
      for (final item in shootingData)
        LetterShootingWord.fromJson(item as Map<String, dynamic>),
    ];

    expect(words, hasLength(42));
    expect(animalWords, hasLength(30));
    expect(objects, hasLength(42));
    expect(sentences, hasLength(12));
    expect(shootingWords.map((word) => word.word), [
      'ANYA',
      'APA',
      'TESTVÉR',
      'NŐVÉR',
      'NÉNI',
      'BÁCSI',
    ]);
    expect(
      words.map((word) => word.word),
      containsAll(['[cs]észe', '[dzs]eki']),
    );
    for (final word in words) {
      expect(File(word.imagePath).existsSync(), isTrue, reason: word.imagePath);
      expect(File(word.audioPath).existsSync(), isTrue, reason: word.audioPath);
      await rootBundle.load(word.imagePath);
      await rootBundle.load(word.audioPath);
    }
    for (final word in animalWords) {
      expect(File(word.imagePath).existsSync(), isTrue, reason: word.imagePath);
      expect(File(word.audioPath).existsSync(), isTrue, reason: word.audioPath);
      await rootBundle.load(word.imagePath);
      await rootBundle.load(word.audioPath);
    }
    for (final sentence in sentences) {
      expect(
        File(sentence.audioPath).existsSync(),
        isTrue,
        reason: sentence.audioPath,
      );
      await rootBundle.load(sentence.audioPath);
    }
    expect(
      objects.singleWhere((object) => object.letter == 'TY').letterTokens,
      ['K', 'E', 'SZ', 'TY', 'Ű'],
    );
    expect(
      factory.contentVersionFor(ActivityId.letterPractice, 'en-1'),
      'hu-1',
    );
    expect(
      factory.contentVersionFor(ActivityId.letterLearning, 'en-1'),
      'hu-1',
    );
    expect(
      factory.contentVersionFor(ActivityId.letterDragging, 'en-1'),
      'hu-1',
    );
    expect(
      factory.contentVersionFor(ActivityId.missingLetters, 'en-1'),
      'hu-1',
    );
    expect(factory.contentVersionFor(ActivityId.memoryCards, 'en-1'), 'hu-1');
    expect(factory.contentVersionFor(ActivityId.wordConveyor, 'en-1'), 'hu-1');
    expect(factory.contentVersionFor(ActivityId.spellingQuiz, 'en-1'), 'hu-1');
    expect(factory.contentVersionFor(ActivityId.sentenceQuiz, 'en-1'), 'hu-1');
    expect(
      factory.contentVersionFor(ActivityId.sentenceComposer, 'en-1'),
      'hu-1',
    );
    expect(
      factory.contentVersionFor(ActivityId.letterCatching, 'en-1'),
      'hu-1',
    );
    expect(
      factory.contentVersionFor(ActivityId.phraseBuilding, 'en-1'),
      'hu-1',
    );
    expect(
      factory.contentVersionFor(ActivityId.letterShooting, 'en-1'),
      'hu-1',
    );
    expect(factory.contentVersionFor(ActivityId.crossword, 'en-1'), 'hu-1');
    expect(factory.crosswordWordsPath, 'assets/data/crossword_words_hu.json');
    expect(factory.letterShootingVowels, ['A', 'E', 'É', 'Ő', 'I', 'Á']);
  });
}
