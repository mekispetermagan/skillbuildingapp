import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/models/missing_letters_word.dart';

void main() {
  test('normalizes a missing-letters word from JSON', () {
    final word = MissingLettersWord.fromJson(const {
      'id': 4,
      'word': ' gorilla ',
      'image_path': 'assets/images/ugandan_animals/gorilla.png',
    });

    expect(word.id, 4);
    expect(word.word, 'GORILLA');
    expect(word.imagePath, 'assets/images/ugandan_animals/gorilla.png');
  });

  test('rejects words shorter than two letters', () {
    expect(
      () => MissingLettersWord.fromJson(const {
        'id': 1,
        'word': 'a',
        'image_path': 'a.png',
      }),
      throwsFormatException,
    );
  });
}
