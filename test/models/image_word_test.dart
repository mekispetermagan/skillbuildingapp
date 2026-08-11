import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/models/image_word.dart';

void main() {
  test('normalizes a shared animal image word', () {
    final word = ImageWord.fromJson(const {
      'id': 1,
      'word': ' Guinea Fowl ',
      'image_path': ' animals/guinea_fowl.png ',
    });

    expect(word.word, 'guinea fowl');
    expect(word.uppercaseWord, 'GUINEA FOWL');
    expect(word.imagePath, 'animals/guinea_fowl.png');
  });

  test('rejects empty image paths', () {
    expect(
      () =>
          ImageWord.fromJson(const {'id': 1, 'word': 'goat', 'image_path': ''}),
      throwsFormatException,
    );
  });
}
