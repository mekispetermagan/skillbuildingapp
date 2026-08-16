import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/audio/asset_audio_player.dart';
import 'package:literacy_game/controllers/session_controller.dart';
import 'package:literacy_game/models/activity_id.dart';
import 'package:literacy_game/models/learning_area.dart';
import 'package:literacy_game/models/pending_completion.dart';
import 'package:literacy_game/models/play_outcome.dart';
import 'package:literacy_game/services/gameplay_recorder.dart';

class _FakeAudioPlayer implements AssetAudioPlayer {
  final playedPaths = <String>[];

  @override
  Future<void> play(String assetPath) async => playedPaths.add(assetPath);

  @override
  Future<void> stop() async {}
}

class _FakeGameplayRecorder implements GameplayRecorder {
  final abandoned = <PendingCompletion>[];
  final completed = <(PendingCompletion, int)>[];
  int synchronizationCount = 0;

  @override
  Future<void> synchronize() async => synchronizationCount++;

  @override
  Future<void> recordAbandoned(PendingCompletion completion) async {
    abandoned.add(completion);
  }

  @override
  Future<void> recordCompleted(PendingCompletion completion, int rating) async {
    completed.add((completion, rating));
  }
}

class _SentenceAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    throw UnimplementedError();
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
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
          {"id": 1, "letter": "a", "color": "red", "difficulty": "beginner", "audio_path": "audio/A.mp3"},
          {"id": 2, "letter": "m", "color": "orange", "difficulty": "beginner", "audio_path": "audio/M.mp3"},
          {"id": 3, "letter": "s", "color": "amber", "difficulty": "beginner", "audio_path": "audio/S.mp3"},
          {"id": 4, "letter": "t", "color": "green", "difficulty": "beginner", "audio_path": "audio/T.mp3"},
          {"id": 5, "letter": "p", "color": "teal", "difficulty": "beginner", "audio_path": "audio/P.mp3"},
          {"id": 6, "letter": "f", "color": "blue", "difficulty": "beginner", "audio_path": "audio/F.mp3"},
          {"id": 7, "letter": "i", "color": "deepPurple", "difficulty": "beginner", "audio_path": "audio/I.mp3"},
          {"id": 8, "letter": "n", "color": "pink", "difficulty": "beginner", "audio_path": "audio/N.mp3"},
          {"id": 9, "letter": "o", "color": "brown", "difficulty": "beginner", "audio_path": "audio/O.mp3"}
        ]
      ''';
    }
    if (key == 'assets/data/alphabet_objects.json') {
      return '''
        [
          {"id": 1, "letter": "A", "word": "apple", "audio_path": "audio/apple.mp3", "image_path": "images/apple.png"},
          {"id": 2, "letter": "M", "word": "match", "audio_path": "audio/match.mp3", "image_path": "images/match.png"},
          {"id": 3, "letter": "S", "word": "soap", "audio_path": "audio/soap.mp3", "image_path": "images/soap.png"}
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
  test('exposes all thirteen activities', () async {
    final controller = SessionController(
      assetBundle: _SentenceAssetBundle(),
      audioPlayer: _FakeAudioPlayer(),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.status, SessionStatus.areaMenu);
    expect(controller.literacyMenuItems.map((item) => item.$1), [
      ActivityId.letterLearning,
      ActivityId.letterPractice,
      ActivityId.phraseBuilding,
      ActivityId.letterDragging,
      ActivityId.missingLetters,
      ActivityId.letterShooting,
      ActivityId.memoryCards,
      ActivityId.letterCatching,
      ActivityId.wordConveyor,
      ActivityId.sentenceQuiz,
      ActivityId.sentenceComposer,
      ActivityId.spellingQuiz,
      ActivityId.crossword,
    ]);
    expect(controller.phraseBuildingViewData.isLoading, isFalse);
    expect(controller.phraseBuildingViewData.loadError, isNull);
    expect(controller.letterDraggingViewData.isLoading, isFalse);
    expect(controller.letterDraggingViewData.loadError, isNull);
    expect(controller.missingLettersViewData.isLoading, isFalse);
    expect(controller.missingLettersViewData.loadError, isNull);
    expect(controller.memoryViewData.isLoading, isFalse);
    expect(controller.memoryViewData.loadError, isNull);
    expect(controller.letterShootingViewData.isLoading, isFalse);
    expect(controller.letterShootingViewData.loadError, isNull);
    expect(controller.letterCatchingViewData.isLoading, isFalse);
    expect(controller.letterCatchingViewData.loadError, isNull);
    expect(controller.conveyorViewData.isLoading, isFalse);
    expect(controller.conveyorViewData.loadError, isNull);
    expect(controller.spellingQuizViewData.isLoading, isFalse);
    expect(controller.spellingQuizViewData.loadError, isNull);
    expect(controller.crosswordViewData.isLoading, isFalse);
    expect(controller.crosswordViewData.loadError, isNull);
    expect(controller.letterLearningViewData.isLoading, isFalse);
    expect(controller.letterLearningViewData.loadError, isNull);
    expect(controller.letterPracticeViewData.isLoading, isFalse);
    expect(controller.letterPracticeViewData.loadError, isNull);

    controller.literacyMenuItems[4].$2();
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
    controller.openLiteracyMenu();
    controller.literacyMenuItems[2].$2();
    expect(controller.phraseBuildingViewData.targetPool, isEmpty);

    final firstCard = controller.memoryViewData.cards.first;
    await controller.memorySelect(firstCard.cardId);
    expect(
      controller.memoryViewData.cards.where((card) => card.isFaceUp),
      isNotEmpty,
    );
    controller.openLiteracyMenu();
    controller.literacyMenuItems[6].$2();
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

  test('back records an abandoned activity before returning to menu', () async {
    final recorder = _FakeGameplayRecorder();
    var now = DateTime.utc(2026, 8, 16, 10);
    final controller = SessionController(
      assetBundle: _SentenceAssetBundle(),
      audioPlayer: _FakeAudioPlayer(),
      gameplayRecorder: recorder,
      now: () => now,
    );
    await Future<void>.delayed(Duration.zero);

    controller.openPhraseBuilding();
    now = now.add(const Duration(seconds: 12));
    controller.openLiteracyMenu();
    await Future<void>.delayed(Duration.zero);

    expect(controller.status, SessionStatus.literacyMenu);
    expect(recorder.abandoned, hasLength(1));
    expect(recorder.abandoned.single.feature, ActivityId.phraseBuilding);
    expect(recorder.abandoned.single.outcome, PlayOutcome.abandoned);
    expect(recorder.abandoned.single.elapsedMilliseconds, 12000);
    controller.dispose();
  });

  test(
    'finished gameplay requires a rating before returning to menu',
    () async {
      final recorder = _FakeGameplayRecorder();
      final controller = SessionController(
        assetBundle: _SentenceAssetBundle(),
        audioPlayer: _FakeAudioPlayer(),
        gameplayRecorder: recorder,
      );
      await Future<void>.delayed(Duration.zero);

      controller.openLetterShooting();
      controller.letterShootingViewData.world!.score = 10;
      controller.letterShootingTick(0);

      expect(controller.status, SessionStatus.rating);
      expect(controller.ratingActivity, ActivityId.letterShooting);

      await controller.submitRating(5);

      expect(controller.status, SessionStatus.literacyMenu);
      expect(recorder.completed, hasLength(1));
      expect(recorder.completed.single.$1.outcome, PlayOutcome.won);
      expect(recorder.completed.single.$2, 5);
      controller.dispose();
    },
  );

  test('area and math menus use the expected navigation hierarchy', () {
    final controller = SessionController(
      assetBundle: _SentenceAssetBundle(),
      audioPlayer: _FakeAudioPlayer(),
    );

    controller.openMathMenu();
    expect(controller.status, SessionStatus.mathMenu);
    expect(controller.mathMenuItems, hasLength(8));

    controller.mathMenuItems.last.$2();
    expect(controller.status, SessionStatus.mathPlaceholder);
    expect(controller.mathPlaceholderNumber, 8);

    controller.handleBack();
    expect(controller.status, SessionStatus.mathMenu);
    controller.handleBack();
    expect(controller.status, SessionStatus.areaMenu);
    controller.dispose();
  });

  test('number learning abandonment is recorded in the math area', () async {
    final recorder = _FakeGameplayRecorder();
    final controller = SessionController(
      assetBundle: _SentenceAssetBundle(),
      audioPlayer: _FakeAudioPlayer(),
      gameplayRecorder: recorder,
    );

    controller.mathMenuItems.first.$2();
    expect(controller.status, SessionStatus.numberLearning);
    controller.openMathMenu();
    await Future<void>.delayed(Duration.zero);

    expect(recorder.abandoned, hasLength(1));
    expect(recorder.abandoned.single.area, LearningArea.math);
    expect(recorder.abandoned.single.feature, ActivityId.numberLearning);
    expect(controller.status, SessionStatus.mathMenu);
    controller.dispose();
  });
}
