import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/models/alphabet_object.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'object catalog has one unique word, audio file, and image per letter',
    () async {
      final encoded = await rootBundle.loadString(
        'assets/data/alphabet_objects.json',
      );
      final data = jsonDecode(encoded) as List<dynamic>;
      final objects = [
        for (final item in data)
          AlphabetObject.fromJson(item as Map<String, dynamic>),
      ];

      expect(objects, hasLength(26));
      expect(objects.map((item) => item.id).toSet(), hasLength(26));
      expect(objects.map((item) => item.letter).toSet(), hasLength(26));
      expect(objects.map((item) => item.word).toSet(), hasLength(26));
      for (final item in objects) {
        expect(
          File(item.audioPath).existsSync(),
          isTrue,
          reason: item.audioPath,
        );
        expect(
          File(item.imagePath).existsSync(),
          isTrue,
          reason: item.imagePath,
        );
      }
    },
  );

  test('normalizes an alphabet object', () {
    final object = AlphabetObject.fromJson(const {
      'id': 1,
      'letter': ' a ',
      'word': ' Apple ',
      'audio_path': ' audio/apple.mp3 ',
      'image_path': ' images/apple.png ',
    });

    expect(object.letter, 'A');
    expect(object.word, 'apple');
    expect(object.audioPath, 'audio/apple.mp3');
    expect(object.imagePath, 'images/apple.png');
  });
}
