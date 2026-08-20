import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/models/sentence.dart';

void main() {
  test('creates a sentence from asset JSON', () {
    final sentence = Sentence.fromJson(const {
      'id': 7,
      'string': 'A short sentence.',
      'audio_path': 'assets/audio/sentences/007.mp3',
    });

    expect(sentence.id, 7);
    expect(sentence.text, 'A short sentence.');
    expect(sentence.audioPath, 'assets/audio/sentences/007.mp3');
  });

  test('rejects malformed sentence assets consistently', () {
    expect(
      () => Sentence.fromJson(const {
        'id': 1,
        'string': '',
        'audio_path': 'sentence.mp3',
      }),
      throwsFormatException,
    );
  });
}
