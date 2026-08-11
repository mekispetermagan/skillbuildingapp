import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../audio/asset_audio_player.dart';
import '../models/answer_feedback.dart';
import '../models/conveyor_state.dart';
import '../models/image_word.dart';
import '../models/letter_catching_state.dart';
import '../models/letter_catching_word.dart';
import '../models/letter_dragging_state.dart';
import '../models/letter_dragging_word.dart';
import '../models/letter_shooting_state.dart';
import '../models/letter_shooting_word.dart';
import '../models/letter_shooting_world.dart';
import '../models/missing_letters_state.dart';
import '../models/missing_letters_word.dart';
import '../models/outfit_sentence.dart';
import '../models/phrase_building_state.dart';
import '../models/phrase_building_tile.dart';
import '../models/sentence.dart';
import '../models/sentence_composer_state.dart';
import '../models/view_data.dart';
import 'conveyor_controller.dart';
import 'letter_catching_controller.dart';
import 'letter_dragging_controller.dart';
import 'letter_shooting_controller.dart';
import 'memory_controller.dart';
import 'missing_letters_controller.dart';
import 'phrase_building_controller.dart';
import 'sentence_composer_controller.dart';
import 'sentence_quiz_controller.dart';

enum SessionStatus {
  menu,
  phraseBuilding,
  letterDragging,
  missingLetters,
  letterShooting,
  memory,
  letterCatching,
  conveyor,
  sentenceQuiz,
  sentenceComposer,
}

class SessionController extends ChangeNotifier {
  final AssetBundle _assetBundle;
  final AssetAudioPlayer _audioPlayer;

  PhraseBuildingController? _phraseBuildingController;
  String? _phraseBuildingError;
  LetterDraggingController? _letterDraggingController;
  String? _letterDraggingError;
  LetterShootingController? _letterShootingController;
  String? _letterShootingError;
  LetterCatchingController? _letterCatchingController;
  String? _letterCatchingError;
  ConveyorController? _conveyorController;
  String? _conveyorError;
  MissingLettersController? _missingLettersController;
  String? _missingLettersError;
  MemoryController? _memoryController;
  String? _memoryError;
  bool _disposed = false;
  late final SentenceQuizController _sentenceQuizController;
  late final SentenceComposerController _sentenceComposerController;
  SessionStatus status = SessionStatus.menu;

  SessionController({AssetBundle? assetBundle, AssetAudioPlayer? audioPlayer})
    : _assetBundle = assetBundle ?? rootBundle,
      _audioPlayer = audioPlayer ?? SoloudAssetAudioPlayer() {
    _sentenceQuizController = SentenceQuizController()
      ..addListener(_forwardFeatureNotification);
    _sentenceComposerController = SentenceComposerController()
      ..addListener(_forwardFeatureNotification);
    unawaited(_initializePhraseBuilding());
    unawaited(_initializeLetterDragging());
    unawaited(_initializeLetterShooting());
    unawaited(_initializeLetterCatching());
    unawaited(_initializeConveyor());
    unawaited(_initializeMissingLetters());
    unawaited(_initializeMemory());
  }

  late final List<(String, VoidCallback)> menuItems = [
    ('Phrase building', openPhraseBuilding),
    ('Letter dragging', openLetterDragging),
    ('Missing letters', openMissingLetters),
    ('Letter shooting', openLetterShooting),
    ('Memory cards', openMemory),
    ('Letter catching', openLetterCatching),
    ('Word conveyor', openConveyor),
    ('Sentence quiz', openSentenceQuiz),
    ('Sentence composer', openSentenceComposer),
  ];

  PhraseBuildingViewData get phraseBuildingViewData => PhraseBuildingViewData(
    isLoading:
        _phraseBuildingController == null && _phraseBuildingError == null,
    errorMessage: _phraseBuildingError,
    sourcePool: _phraseBuildingController?.sourcePool ?? const [],
    targetPool: _phraseBuildingController?.targetPool ?? const [],
    state: _phraseBuildingController?.state ?? PhraseBuildingState.guessing,
  );

  void Function(PhraseBuildingTile)? get phraseBuildingMove {
    final controller = _phraseBuildingController;
    return controller != null && controller.canMove ? controller.move : null;
  }

  Future<void> Function()? get phraseBuildingSubmit {
    final controller = _phraseBuildingController;
    return controller != null && controller.canSubmit
        ? controller.submit
        : null;
  }

  Future<void> phraseBuildingPlayAudio() =>
      _phraseBuildingController?.playAudio() ?? Future.value();

  void openPhraseBuilding() {
    _phraseBuildingController?.start();
    _open(SessionStatus.phraseBuilding);
  }

  LetterDraggingViewData get letterDraggingViewData => LetterDraggingViewData(
    isLoading:
        _letterDraggingController == null && _letterDraggingError == null,
    errorMessage: _letterDraggingError,
    tiles: _letterDraggingController?.tiles ?? const [],
    state: _letterDraggingController?.state ?? LetterDraggingState.playing,
    score: _letterDraggingController?.score ?? 0,
    countdown: _letterDraggingController?.countdown.status,
  );

  void Function(int, int)? get letterDraggingReorder {
    final controller = _letterDraggingController;
    return controller != null && controller.canReorder
        ? controller.reorder
        : null;
  }

  VoidCallback? get letterDraggingPass {
    final controller = _letterDraggingController;
    return controller != null && controller.canPass ? controller.pass : null;
  }

  void openLetterDragging() {
    _letterDraggingController?.start();
    _open(SessionStatus.letterDragging);
  }

  void restartLetterDragging() => _letterDraggingController?.start();

  LetterShootingViewData get letterShootingViewData => LetterShootingViewData(
    isLoading:
        _letterShootingController == null && _letterShootingError == null,
    errorMessage: _letterShootingError,
    world: _letterShootingController?.world,
    state: _letterShootingController?.state ?? LetterShootingState.playing,
  );

  void letterShootingResize(double width, double height) =>
      _letterShootingController?.resize(width, height);
  void letterShootingTick(double deltaSeconds) =>
      _letterShootingController?.tick(deltaSeconds);
  void letterShootingTap(GamePoint point) =>
      _letterShootingController?.tap(point);
  void letterShootingBeginAim(GamePoint point) =>
      _letterShootingController?.beginAim(point);
  void letterShootingUpdateAim(GamePoint point) =>
      _letterShootingController?.updateAim(point);
  void letterShootingReleaseAim() => _letterShootingController?.releaseAim();

  void openLetterShooting() {
    _letterShootingController?.start();
    _open(SessionStatus.letterShooting);
  }

  void restartLetterShooting() => _letterShootingController?.start();

  LetterCatchingViewData get letterCatchingViewData => LetterCatchingViewData(
    isLoading:
        _letterCatchingController == null && _letterCatchingError == null,
    errorMessage: _letterCatchingError,
    world: _letterCatchingController?.world,
    state: _letterCatchingController?.state ?? LetterCatchingState.playing,
  );

  void letterCatchingResize(double width, double height) =>
      _letterCatchingController?.resize(width, height);
  void letterCatchingTick(double deltaSeconds) =>
      _letterCatchingController?.tick(deltaSeconds);
  void letterCatchingMovePaddleBy(double deltaX) =>
      _letterCatchingController?.movePaddleBy(deltaX);

  void openLetterCatching() {
    _letterCatchingController?.start();
    _open(SessionStatus.letterCatching);
  }

  void restartLetterCatching() => _letterCatchingController?.start();

  ConveyorViewData get conveyorViewData => ConveyorViewData(
    isLoading: _conveyorController == null && _conveyorError == null,
    errorMessage: _conveyorError,
    world: _conveyorController?.world,
    state: _conveyorController?.state ?? ConveyorState.playing,
  );

  void conveyorResize(double width, double height) =>
      _conveyorController?.resize(width, height);
  ConveyorState conveyorTick(double deltaSeconds) =>
      _conveyorController?.tick(deltaSeconds) ?? ConveyorState.playing;
  bool conveyorCanAccept({required int letterId, required int shelfId}) =>
      _conveyorController?.canAccept(letterId: letterId, shelfId: shelfId) ??
      false;
  void conveyorStartDragging(int letterId) =>
      _conveyorController?.startDragging(letterId);
  void conveyorCancelDragging(int letterId) =>
      _conveyorController?.cancelDragging(letterId);
  void conveyorDrop({required int letterId, required int shelfId}) =>
      _conveyorController?.drop(letterId: letterId, shelfId: shelfId);

  void openConveyor() {
    _conveyorController?.start();
    _open(SessionStatus.conveyor);
  }

  void restartConveyor() => _conveyorController?.start();

  SentenceQuizViewData get sentenceQuizViewData => SentenceQuizViewData(
    question: _sentenceQuizController.question,
    state: _sentenceQuizController.state,
    score: _sentenceQuizController.score,
    correctHighlightIndex: _sentenceQuizController.correctHighlightIndex,
    wrongHighlightIndex: _sentenceQuizController.wrongHighlightIndex,
    canSubmit: _sentenceQuizController.canSubmit,
  );

  Future<void> sentenceQuizSubmit(int guessIndex) =>
      _sentenceQuizController.submit(guessIndex);

  void openSentenceQuiz() {
    _sentenceQuizController.start();
    _open(SessionStatus.sentenceQuiz);
  }

  void restartSentenceQuiz() => _sentenceQuizController.start();

  SentenceComposerViewData get sentenceComposerViewData =>
      SentenceComposerViewData(
        outfit: _sentenceComposerController.outfit,
        selectedPerson: _sentenceComposerController.selectedPerson,
        selectedColor: _sentenceComposerController.selectedColor,
        selectedPiece: _sentenceComposerController.selectedPiece,
        state: _sentenceComposerController.state,
        score: _sentenceComposerController.score,
        composedSentence: _sentenceComposerController.composedSentence,
        canSelect: _sentenceComposerController.canSelect,
        canSubmit: _sentenceComposerController.canSubmit,
        personFeedback: {
          for (final person in SentencePerson.values)
            person: _answerFeedback(
              _sentenceComposerController.personFeedback(person),
            ),
        },
        colorFeedback: {
          for (final color in GarmentColor.values)
            color: _answerFeedback(
              _sentenceComposerController.colorFeedback(color),
            ),
        },
        pieceFeedback: {
          for (final piece in ClothingPiece.values)
            piece: _answerFeedback(
              _sentenceComposerController.pieceFeedback(piece),
            ),
        },
      );

  void sentenceComposerSelectPerson(SentencePerson person) =>
      _sentenceComposerController.selectPerson(person);
  void sentenceComposerSelectColor(GarmentColor color) =>
      _sentenceComposerController.selectColor(color);
  void sentenceComposerSelectPiece(ClothingPiece piece) =>
      _sentenceComposerController.selectPiece(piece);
  Future<void> sentenceComposerSubmit() => _sentenceComposerController.submit();

  void openSentenceComposer() {
    _sentenceComposerController.start();
    _open(SessionStatus.sentenceComposer);
  }

  void restartSentenceComposer() => _sentenceComposerController.start();

  MissingLettersViewData get missingLettersViewData => MissingLettersViewData(
    isLoading:
        _missingLettersController == null && _missingLettersError == null,
    errorMessage: _missingLettersError,
    slots: _missingLettersController?.slots ?? const [],
    pool: _missingLettersController?.pool ?? const [],
    state: _missingLettersController?.state ?? MissingLettersState.solving,
    score: _missingLettersController?.score ?? 0,
  );
  VoidCallback? get missingLettersNext =>
      _missingLettersController?.canContinue == true
      ? _missingLettersController!.next
      : null;

  bool missingLettersCanDrop({required int targetId, required int tileId}) =>
      _missingLettersController?.canDrop(targetId: targetId, tileId: tileId) ??
      false;

  void missingLettersDrop({required int targetId, required int tileId}) =>
      _missingLettersController?.drop(targetId: targetId, tileId: tileId);

  void openMissingLetters() {
    _missingLettersController?.start();
    _open(SessionStatus.missingLetters);
  }

  MemoryViewData get memoryViewData => MemoryViewData(
    isLoading: _memoryController == null && _memoryError == null,
    errorMessage: _memoryError,
    cards: _memoryController?.cards ?? const [],
    isComplete: _memoryController?.isComplete ?? false,
    config: _memoryController?.config ?? memoryConfig,
  );
  Future<void> memorySelect(int cardId) =>
      _memoryController?.select(cardId) ?? Future.value();
  void memoryStartNewGame() => _memoryController?.startNewGame();

  void openMemory() {
    _memoryController?.startNewGame();
    _open(SessionStatus.memory);
  }

  AnswerFeedback _answerFeedback(ComposerChoiceAssessment assessment) =>
      switch (assessment) {
        ComposerChoiceAssessment.neutral => AnswerFeedback.neutral,
        ComposerChoiceAssessment.correct => AnswerFeedback.correct,
        ComposerChoiceAssessment.wrong => AnswerFeedback.wrong,
      };

  void openMenu() {
    unawaited(_audioPlayer.stop());
    _phraseBuildingController?.stop();
    _letterDraggingController?.stop();
    _letterShootingController?.stop();
    _letterCatchingController?.stop();
    _conveyorController?.stop();
    _memoryController?.stop();
    _sentenceQuizController.stop();
    _sentenceComposerController.stop();
    _open(SessionStatus.menu);
  }

  void _open(SessionStatus nextStatus) {
    status = nextStatus;
    notifyListeners();
  }

  Future<void> _initializePhraseBuilding() async {
    try {
      final encoded = await _assetBundle.loadString(
        'assets/data/sentences_en.json',
      );
      final data = jsonDecode(encoded) as List<dynamic>;
      final sentences = [
        for (final item in data)
          Sentence.fromJson(item as Map<String, dynamic>),
      ];
      if (_disposed) return;

      _phraseBuildingController = PhraseBuildingController(
        _audioPlayer,
        sentences: sentences,
      )..addListener(_forwardFeatureNotification);
    } catch (_) {
      if (_disposed) return;
      _phraseBuildingError = 'Could not load the sentence activity.';
    }
    notifyListeners();
  }

  Future<void> _initializeLetterDragging() async {
    try {
      final encoded = await _assetBundle.loadString(
        'assets/data/animal_words.json',
      );
      final data = jsonDecode(encoded) as List<dynamic>;
      final words = [
        for (final item in data)
          LetterDraggingWord.fromJson(item as Map<String, dynamic>),
      ];
      if (_disposed) return;

      _letterDraggingController = LetterDraggingController(
        _audioPlayer,
        words: words,
      )..addListener(_forwardFeatureNotification);
      if (status == SessionStatus.letterDragging) {
        _letterDraggingController!.start();
      }
    } catch (_) {
      if (_disposed) return;
      _letterDraggingError = 'Could not load the letter-dragging activity.';
    }
    notifyListeners();
  }

  Future<void> _initializeMissingLetters() async {
    try {
      final encoded = await _assetBundle.loadString(
        'assets/data/animal_words.json',
      );
      final data = jsonDecode(encoded) as List<dynamic>;
      final words = [
        for (final item in data)
          MissingLettersWord.fromJson(item as Map<String, dynamic>),
      ];
      if (_disposed) return;

      _missingLettersController = MissingLettersController(words: words)
        ..addListener(_forwardFeatureNotification);
      if (status == SessionStatus.missingLetters) {
        _missingLettersController!.start();
      }
    } catch (_) {
      if (_disposed) return;
      _missingLettersError = 'Could not load the missing-letters activity.';
    }
    notifyListeners();
  }

  Future<void> _initializeLetterShooting() async {
    try {
      final encoded = await _assetBundle.loadString(
        'assets/data/letter_shooting_words.json',
      );
      final data = jsonDecode(encoded) as List<dynamic>;
      final words = [
        for (final item in data)
          LetterShootingWord.fromJson(item as Map<String, dynamic>),
      ];
      if (_disposed) return;

      _letterShootingController = LetterShootingController(words: words)
        ..addListener(_forwardFeatureNotification);
      if (status == SessionStatus.letterShooting) {
        _letterShootingController!.start();
      }
    } catch (_) {
      if (_disposed) return;
      _letterShootingError = 'Could not load the letter-shooting activity.';
    }
    notifyListeners();
  }

  Future<void> _initializeLetterCatching() async {
    try {
      final encoded = await _assetBundle.loadString(
        'assets/data/letter_catching_words.json',
      );
      final data = jsonDecode(encoded) as List<dynamic>;
      final words = [
        for (final item in data)
          LetterCatchingWord.fromJson(item as Map<String, dynamic>),
      ];
      if (_disposed) return;

      _letterCatchingController = LetterCatchingController(words: words)
        ..addListener(_forwardFeatureNotification);
      if (status == SessionStatus.letterCatching) {
        _letterCatchingController!.start();
      }
    } catch (_) {
      if (_disposed) return;
      _letterCatchingError = 'Could not load the letter-catching activity.';
    }
    notifyListeners();
  }

  Future<void> _initializeMemory() async {
    try {
      final encoded = await _assetBundle.loadString(
        'assets/data/animal_image_words.json',
      );
      final data = jsonDecode(encoded) as List<dynamic>;
      final pairs = [
        for (final item in data)
          ImageWord.fromJson(item as Map<String, dynamic>),
      ];
      if (_disposed) return;

      _memoryController = MemoryController(pairs: pairs)
        ..addListener(_forwardFeatureNotification);
    } catch (_) {
      if (_disposed) return;
      _memoryError = 'Could not load the memory-card activity.';
    }
    notifyListeners();
  }

  Future<void> _initializeConveyor() async {
    try {
      final encoded = await _assetBundle.loadString(
        'assets/data/animal_image_words.json',
      );
      final data = jsonDecode(encoded) as List<dynamic>;
      final words = [
        for (final item in data)
          ImageWord.fromJson(item as Map<String, dynamic>),
      ];
      if (_disposed) return;

      _conveyorController = ConveyorController(words: words);
      if (status == SessionStatus.conveyor) {
        _conveyorController!.start();
      }
    } catch (_) {
      if (_disposed) return;
      _conveyorError = 'Could not load the word-conveyor activity.';
    }
    notifyListeners();
  }

  void _forwardFeatureNotification() => notifyListeners();

  @override
  void dispose() {
    _disposed = true;
    unawaited(_audioPlayer.stop());
    _phraseBuildingController?.removeListener(_forwardFeatureNotification);
    _phraseBuildingController?.dispose();
    _letterDraggingController?.removeListener(_forwardFeatureNotification);
    _letterDraggingController?.dispose();
    _letterShootingController?.removeListener(_forwardFeatureNotification);
    _letterShootingController?.dispose();
    _letterCatchingController?.removeListener(_forwardFeatureNotification);
    _letterCatchingController?.dispose();
    _conveyorController?.dispose();
    _missingLettersController?.removeListener(_forwardFeatureNotification);
    _missingLettersController?.dispose();
    _memoryController?.removeListener(_forwardFeatureNotification);
    _memoryController?.dispose();
    _sentenceQuizController.removeListener(_forwardFeatureNotification);
    _sentenceQuizController.dispose();
    _sentenceComposerController.removeListener(_forwardFeatureNotification);
    _sentenceComposerController.dispose();
    super.dispose();
  }
}
