import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/audio/asset_audio_player.dart';
import 'package:literacy_game/controllers/session_controller.dart';

class _FakeAudioPlayer implements AssetAudioPlayer {
  final playedPaths = <String>[];

  @override
  Future<void> play(String assetPath) async => playedPaths.add(assetPath);

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
          {"id": 1, "word": "cat", "image_path": "one.png", "audio_path": "one.mp3"},
          {"id": 2, "word": "cow", "image_path": "two.png", "audio_path": "two.mp3"},
          {"id": 3, "word": "dog", "image_path": "three.png", "audio_path": "three.mp3"},
          {"id": 4, "word": "duck", "image_path": "four.png", "audio_path": "four.mp3"},
          {"id": 5, "word": "goat", "image_path": "five.png", "audio_path": "five.mp3"},
          {"id": 6, "word": "lion", "image_path": "six.png", "audio_path": "six.mp3"},
          {"id": 7, "word": "pig", "image_path": "seven.png", "audio_path": "seven.mp3"},
          {"id": 8, "word": "sheep", "image_path": "eight.png", "audio_path": "eight.mp3"},
          {"id": 9, "word": "zebra", "image_path": "nine.png", "audio_path": "nine.mp3"}
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
    if (key == 'assets/data/crossword_words.json') {
      return '''
        [
          {"word": "cat", "clue": "A pet that says meow."},
          {"word": "car", "clue": "A small road vehicle."},
          {"word": "bar", "clue": "A long solid piece."},
          {"word": "bat", "clue": "An animal that flies at night."},
          {"word": "rat", "clue": "An animal like a large mouse."},
          {"word": "tar", "clue": "A dark road material."}
        ]
      ''';
    }
    if (key == 'assets/data/alphabet_progression.json') {
      return '''
        [
          {"id": 1, "letter": "a", "color": "red", "difficulty": "beginner"},
          {"id": 2, "letter": "m", "color": "orange", "difficulty": "beginner"},
          {"id": 3, "letter": "s", "color": "amber", "difficulty": "beginner"},
          {"id": 4, "letter": "t", "color": "green", "difficulty": "beginner"},
          {"id": 5, "letter": "p", "color": "teal", "difficulty": "beginner"},
          {"id": 6, "letter": "f", "color": "blue", "difficulty": "beginner"},
          {"id": 7, "letter": "i", "color": "deepPurple", "difficulty": "beginner"},
          {"id": 8, "letter": "n", "color": "pink", "difficulty": "beginner"},
          {"id": 9, "letter": "o", "color": "brown", "difficulty": "beginner"}
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
  test('exposes all twelve activities', () async {
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
      'Crossword',
      'Letter practice',
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
    expect(controller.crosswordViewData.isLoading, isFalse);
    expect(controller.crosswordViewData.errorMessage, isNull);
    expect(controller.letterPracticeViewData.isLoading, isFalse);
    expect(controller.letterPracticeViewData.errorMessage, isNull);

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

  test('opening and restarting spelling quiz autoplay pronunciation', () async {
    final audioPlayer = _FakeAudioPlayer();
    final controller = SessionController(
      assetBundle: _SentenceAssetBundle(),
      audioPlayer: audioPlayer,
    );
    await Future<void>.delayed(Duration.zero);

    controller.openSpellingQuiz();
    await Future<void>.delayed(Duration.zero);
    expect(audioPlayer.playedPaths, hasLength(1));
    expect(
      audioPlayer.playedPaths.single,
      controller.spellingQuizViewData.question!.animal.audioPath,
    );

    controller.restartSpellingQuiz();
    await Future<void>.delayed(Duration.zero);
    expect(audioPlayer.playedPaths, hasLength(2));
    expect(
      audioPlayer.playedPaths.last,
      controller.spellingQuizViewData.question!.animal.audioPath,
    );
    controller.dispose();
  });

  test('opening phrase building autoplays its sentence', () async {
    final audioPlayer = _FakeAudioPlayer();
    final controller = SessionController(
      assetBundle: _SentenceAssetBundle(),
      audioPlayer: audioPlayer,
    );
    await Future<void>.delayed(Duration.zero);

    controller.openPhraseBuilding();
    await Future<void>.delayed(Duration.zero);
    expect(audioPlayer.playedPaths, ['assets/audio/sentences/001.mp3']);

    await controller.phraseBuildingPlayAudio();
    expect(audioPlayer.playedPaths, [
      'assets/audio/sentences/001.mp3',
      'assets/audio/sentences/001.mp3',
    ]);
    controller.dispose();
  });

  test('opening letter practice autoplays its animal word', () async {
    final audioPlayer = _FakeAudioPlayer();
    final controller = SessionController(
      assetBundle: _SentenceAssetBundle(),
      audioPlayer: audioPlayer,
    );
    await Future<void>.delayed(Duration.zero);

    controller.openLetterPractice();
    await Future<void>.delayed(Duration.zero);
    expect(audioPlayer.playedPaths, hasLength(1));
    expect(
      audioPlayer.playedPaths.single,
      controller.letterPracticeViewData.currentWord!.audioPath,
    );
    controller.dispose();
  });
}
