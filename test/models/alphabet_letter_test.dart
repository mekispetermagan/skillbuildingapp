import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/models/alphabet_letter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'asset defines all letters in the expected progression groups',
    () async {
      final encoded = await rootBundle.loadString(
        'assets/data/alphabet_progression.json',
      );
      final data = jsonDecode(encoded) as List<dynamic>;
      final entries = [
        for (final item in data)
          AlphabetLetter.fromJson(item as Map<String, dynamic>),
      ];

      expect(entries, hasLength(26));
      expect(entries.map((entry) => entry.letter).toSet(), hasLength(26));
      expect(
        entries.where(
          (entry) => entry.difficulty == AlphabetDifficulty.beginner,
        ),
        hasLength(9),
      );
      expect(
        entries.where(
          (entry) => entry.difficulty == AlphabetDifficulty.intermediate,
        ),
        hasLength(9),
      );
      expect(
        entries.where(
          (entry) => entry.difficulty == AlphabetDifficulty.advanced,
        ),
        hasLength(8),
      );
      for (final difficulty in AlphabetDifficulty.values) {
        final group = entries
            .where((entry) => entry.difficulty == difficulty)
            .toList();
        expect(
          group.map((entry) => entry.letter),
          orderedEquals(group.map((entry) => entry.letter).toList()..sort()),
        );
        expect(
          group.map((entry) => entry.id),
          orderedEquals(group.map((entry) => entry.id).toList()..sort()),
        );
      }
    },
  );

  test('normalizes an alphabet progression entry', () {
    final entry = AlphabetLetter.fromJson(const {
      'id': 1,
      'letter': ' a ',
      'color': ' red ',
      'difficulty': 'beginner',
    });

    expect(entry.letter, 'A');
    expect(entry.colorName, 'red');
    expect(entry.difficulty, AlphabetDifficulty.beginner);
  });

  test('rejects invalid difficulty values', () {
    expect(
      () => AlphabetLetter.fromJson(const {
        'id': 1,
        'letter': 'a',
        'color': 'red',
        'difficulty': 'expert',
      }),
      throwsFormatException,
    );
  });
}
