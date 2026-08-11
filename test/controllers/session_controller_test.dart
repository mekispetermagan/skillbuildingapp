import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/audio/asset_audio_player.dart';
import 'package:literacy_game/controllers/session_controller.dart';

class _FakeAudioPlayer implements AssetAudioPlayer {
  @override
  Future<void> play(String assetPath) async {}

  @override
  Future<void> stop() async {}
}

class _SentenceAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    throw UnimplementedError();
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'assets/data/letter_dragging_words.json') {
      return '[{"id": 1, "word": "zebra"}]';
    }
    if (key == 'assets/data/memory_pairs.json') {
      return '''
        [
          {"id": 1, "word": "word1", "image_path": "one.png"},
          {"id": 2, "word": "word2", "image_path": "two.png"},
          {"id": 3, "word": "word3", "image_path": "three.png"},
          {"id": 4, "word": "word4", "image_path": "four.png"},
          {"id": 5, "word": "word5", "image_path": "five.png"},
          {"id": 6, "word": "word6", "image_path": "six.png"},
          {"id": 7, "word": "word7", "image_path": "seven.png"},
          {"id": 8, "word": "word8", "image_path": "eight.png"},
          {"id": 9, "word": "word9", "image_path": "nine.png"}
        ]
      ''';
    }
    if (key == 'assets/data/letter_shooting_words.json') {
      return '''
        [
          {"id": 1, "word": "DAD"}
        ]
      ''';
    }
    return '''
      [
        {
          "id": 1,
          "string": "red bird",
          "audio_path": "assets/audio/sentences/001.mp3"
        }
      ]
    ''';
  }
}

void main() {
  test('exposes five activities and three placeholder destinations', () async {
    final controller = SessionController(
      assetBundle: _SentenceAssetBundle(),
      audioPlayer: _FakeAudioPlayer(),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.menuItems.map((item) => item.$1), [
      'Phrase building',
      'Letter dragging',
      'Missing letters',
      'Letter shooting',
      'Memory cards',
      'Feature 6',
      'Feature 7',
      'Feature 8',
    ]);
    expect(controller.phraseBuildingIsLoading, isFalse);
    expect(controller.phraseBuildingError, isNull);
    expect(controller.letterDraggingIsLoading, isFalse);
    expect(controller.letterDraggingError, isNull);
    expect(controller.missingLettersIsLoading, isFalse);
    expect(controller.missingLettersError, isNull);
    expect(controller.memoryIsLoading, isFalse);
    expect(controller.memoryError, isNull);
    expect(controller.letterShootingIsLoading, isFalse);
    expect(controller.letterShootingError, isNull);

    controller.menuItems[2].$2();
    expect(controller.status, SessionStatus.missingLetters);

    controller.dispose();
  });
}
