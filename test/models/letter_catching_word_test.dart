import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/models/letter_catching_word.dart';

void main() {
  test('normalizes a four-to-seven-letter animal word', () {
    final word = LetterCatchingWord.fromJson(const {
      'id': 3,
      'word': ' giraffe ',
    });

    expect(word.id, 3);
    expect(word.word, 'GIRAFFE');
  });

  test('rejects words outside the configured length range', () {
    expect(
      () => LetterCatchingWord.fromJson(const {'id': 1, 'word': 'cat'}),
      throwsFormatException,
    );
  });
}
