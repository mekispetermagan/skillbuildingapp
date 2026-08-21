import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/models/activity_id.dart';
import 'package:skillbuilding_game/models/alphabet_letter.dart';
import 'package:skillbuilding_game/models/interface_language.dart';
import 'package:skillbuilding_game/services/game_content_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Hungarian letter practice uses all localized object assets', () async {
    final encoded = await rootBundle.loadString(
      'assets/data/alphabet_progression_hu.json',
    );
    final data = jsonDecode(encoded) as List<dynamic>;
    final alphabet = [
      for (final item in data)
        AlphabetLetter.fromJson(item as Map<String, dynamic>),
    ];
    final factory = GameContentFactory.forLanguage(InterfaceLanguage.hungarian);

    final words = factory.letterPracticeWords(
      englishWords: const [],
      alphabet: alphabet,
    );

    expect(words, hasLength(42));
    expect(
      words.map((word) => word.word),
      containsAll(['[cs]észe', '[dzs]eki']),
    );
    for (final word in words) {
      expect(File(word.imagePath).existsSync(), isTrue, reason: word.imagePath);
      expect(File(word.audioPath).existsSync(), isTrue, reason: word.audioPath);
    }
    expect(
      factory.contentVersionFor(ActivityId.letterPractice, 'en-1'),
      'hu-1',
    );
    expect(factory.contentVersionFor(ActivityId.memoryCards, 'en-1'), 'en-1');
  });
}
