import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/models/sentence.dart';

void main() {
  test('creates a sentence from asset JSON', () {
    final sentence = Sentence.fromJson(const {
      'id': 7,
      'string': 'A short sentence.',
      'audio_path': 'assets/audio/sentences/007.mp3',
    });

    expect(sentence.id, 7);
    expect(sentence.string, 'A short sentence.');
    expect(sentence.audioPath, 'assets/audio/sentences/007.mp3');
  });
}
