import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/models/letter_dragging_word.dart';

void main() {
  test('normalizes a letter-dragging word from JSON', () {
    final word = LetterDraggingWord.fromJson(const {
      'id': 3,
      'word': ' giraffe ',
    });

    expect(word.id, 3);
    expect(word.word, 'GIRAFFE');
  });

  test('rejects a word that cannot be shuffled', () {
    expect(
      () => LetterDraggingWord.fromJson(const {'id': 1, 'word': 'aaa'}),
      throwsFormatException,
    );
  });
}
