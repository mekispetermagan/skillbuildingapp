import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/models/missing_letters_word.dart';

void main() {
  test('normalizes a missing-letters word from JSON', () {
    final word = MissingLettersWord.fromJson(const {
      'id': 4,
      'word': ' gorilla ',
    });

    expect(word.id, 4);
    expect(word.word, 'GORILLA');
  });

  test('rejects words shorter than two letters', () {
    expect(
      () => MissingLettersWord.fromJson(const {'id': 1, 'word': 'a'}),
      throwsFormatException,
    );
  });
}
