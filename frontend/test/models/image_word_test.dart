import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/models/image_word.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shared animal catalog has unique entries and bundled assets', () async {
    final encoded = await rootBundle.loadString(
      'assets/data/animal_image_words.json',
    );
    final data = jsonDecode(encoded) as List<dynamic>;
    final words = [
      for (final item in data) ImageWord.fromJson(item as Map<String, dynamic>),
    ];

    expect(words, hasLength(30));
    expect(words.map((word) => word.id).toSet(), hasLength(words.length));
    expect(words.map((word) => word.word).toSet(), hasLength(words.length));
    for (final word in words) {
      expect(File(word.imagePath).existsSync(), isTrue, reason: word.imagePath);
      expect(File(word.audioPath).existsSync(), isTrue, reason: word.audioPath);
    }
  });

  test('normalizes a shared animal image word', () {
    final word = ImageWord.fromJson(const {
      'id': 1,
      'word': ' Guinea Fowl ',
      'image_path': ' animals/guinea_fowl.png ',
      'audio_path': ' audio/guinea_fowl.mp3 ',
    });

    expect(word.word, 'guinea fowl');
    expect(word.uppercaseWord, 'GUINEA FOWL');
    expect(word.imagePath, 'animals/guinea_fowl.png');
    expect(word.audioPath, 'audio/guinea_fowl.mp3');
  });

  test('tokenizes bracketed Hungarian letters as single units', () {
    final word = ImageWord.fromJson(const {
      'id': 2,
      'word': ' ve[ssz]ő ',
      'image_path': 'images/vesszo.png',
      'audio_path': 'audio/vesszo.mp3',
    });

    expect(word.letterTokens, ['V', 'E', 'SSZ', 'Ő']);
  });

  test('rejects empty image paths', () {
    expect(
      () => ImageWord.fromJson(const {
        'id': 1,
        'word': 'goat',
        'image_path': '',
        'audio_path': 'audio/goat.mp3',
      }),
      throwsFormatException,
    );
  });

  test('rejects empty audio paths', () {
    expect(
      () => ImageWord.fromJson(const {
        'id': 1,
        'word': 'goat',
        'image_path': 'animals/goat.png',
        'audio_path': '',
      }),
      throwsFormatException,
    );
  });
}
