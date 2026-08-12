import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/models/image_word.dart';

void main() {
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
