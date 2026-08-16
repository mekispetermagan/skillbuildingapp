import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/models/letter_shooting_word.dart';

void main() {
  test('normalizes and validates a word containing a vowel', () {
    final word = LetterShootingWord.fromJson(const {'id': 1, 'word': ' dad '});

    expect(word.word, 'DAD');
  });

  test('rejects a word without a vowel', () {
    expect(
      () => LetterShootingWord.fromJson(const {'id': 1, 'word': 'DRY'}),
      throwsFormatException,
    );
  });
}
