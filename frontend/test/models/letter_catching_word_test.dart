import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/models/letter_catching_word.dart';

void main() {
  test('normalizes an illustrated animal word without a length limit', () {
    final word = LetterCatchingWord.fromJson(const {
      'id': 3,
      'word': ' chimpanzee ',
      'image_path': 'chimpanzee.png',
    });

    expect(word.id, 3);
    expect(word.word, 'CHIMPANZEE');
    expect(word.imagePath, 'chimpanzee.png');
  });

  test('tokenizes a bracketed Hungarian digraph as one letter', () {
    final word = LetterCatchingWord.fromJson(const {
      'id': 1,
      'word': '[ny]úl',
      'image_path': 'nyul.png',
    });

    expect(word.letterTokens, ['NY', 'Ú', 'L']);
  });
}
