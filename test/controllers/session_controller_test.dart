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
    if (key == 'assets/data/animal_words.json') {
      return '[{"id": 1, "word": "zebra"}]';
    }
    if (key == 'assets/data/animal_image_words.json') {
      return '''
        [
          {"id": 1, "word": "cat", "image_path": "one.png"},
          {"id": 2, "word": "cow", "image_path": "two.png"},
          {"id": 3, "word": "dog", "image_path": "three.png"},
          {"id": 4, "word": "duck", "image_path": "four.png"},
          {"id": 5, "word": "goat", "image_path": "five.png"},
          {"id": 6, "word": "lion", "image_path": "six.png"},
          {"id": 7, "word": "pig", "image_path": "seven.png"},
          {"id": 8, "word": "sheep", "image_path": "eight.png"},
          {"id": 9, "word": "zebra", "image_path": "nine.png"}
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
    if (key == 'assets/data/letter_catching_words.json') {
      return '[{"id": 1, "word": "lion"}]';
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
  test('exposes all ten activities', () async {
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
      'Letter catching',
      'Word conveyor',
      'Sentence quiz',
      'Sentence composer',
      'Spelling quiz',
    ]);
    expect(controller.phraseBuildingViewData.isLoading, isFalse);
    expect(controller.phraseBuildingViewData.errorMessage, isNull);
    expect(controller.letterDraggingViewData.isLoading, isFalse);
    expect(controller.letterDraggingViewData.errorMessage, isNull);
    expect(controller.missingLettersViewData.isLoading, isFalse);
    expect(controller.missingLettersViewData.errorMessage, isNull);
    expect(controller.memoryViewData.isLoading, isFalse);
    expect(controller.memoryViewData.errorMessage, isNull);
    expect(controller.letterShootingViewData.isLoading, isFalse);
    expect(controller.letterShootingViewData.errorMessage, isNull);
    expect(controller.letterCatchingViewData.isLoading, isFalse);
    expect(controller.letterCatchingViewData.errorMessage, isNull);
    expect(controller.conveyorViewData.isLoading, isFalse);
    expect(controller.conveyorViewData.errorMessage, isNull);
    expect(controller.spellingQuizViewData.isLoading, isFalse);
    expect(controller.spellingQuizViewData.errorMessage, isNull);

    controller.menuItems[2].$2();
    expect(controller.status, SessionStatus.missingLetters);

    controller.dispose();
  });

  test('opening activities from the menu starts fresh sessions', () async {
    final controller = SessionController(
      assetBundle: _SentenceAssetBundle(),
      audioPlayer: _FakeAudioPlayer(),
    );
    await Future<void>.delayed(Duration.zero);

    final phraseTile = controller.phraseBuildingViewData.sourcePool.first;
    controller.phraseBuildingMove!(phraseTile);
    expect(controller.phraseBuildingViewData.targetPool, isNotEmpty);
    controller.openMenu();
    controller.menuItems[0].$2();
    expect(controller.phraseBuildingViewData.targetPool, isEmpty);

    final firstCard = controller.memoryViewData.cards.first;
    await controller.memorySelect(firstCard.cardId);
    expect(
      controller.memoryViewData.cards.where((card) => card.isFaceUp),
      isNotEmpty,
    );
    controller.openMenu();
    controller.menuItems[4].$2();
    expect(
      controller.memoryViewData.cards.where((card) => card.isFaceUp),
      isEmpty,
    );

    controller.dispose();
  });
}
