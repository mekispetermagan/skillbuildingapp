import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../audio/asset_audio_player.dart';
import '../models/answer_feedback.dart';
import '../models/alphabet_letter.dart';
import '../models/alphabet_object.dart';
import '../models/balance_game.dart';
import '../models/conveyor_state.dart';
import '../models/conveyor_config.dart';
import '../models/crossword_entry.dart';
import '../models/crossword_state.dart';
import '../models/activity_id.dart';
import '../models/feature_load_error.dart';
import '../models/feature_metrics.dart';
import '../models/image_word.dart';
import '../models/interface_language.dart';
import '../models/letter_catching_state.dart';
import '../models/letter_catching_word.dart';
import '../models/letter_dragging_state.dart';
import '../models/letter_dragging_word.dart';
import '../models/letter_learning_state.dart';
import '../models/learning_area.dart';
import '../models/letter_shooting_state.dart';
import '../models/letter_shooting_word.dart';
import '../models/letter_shooting_world.dart';
import '../models/logic_game.dart';
import '../models/letter_practice_state.dart';
import '../models/letter_practice_word_set.dart';
import '../models/missing_letters_state.dart';
import '../models/missing_letters_word.dart';
import '../models/number_learning.dart';
import '../models/number_comparison.dart';
import '../models/number_dragging.dart';
import '../models/number_memory.dart';
import '../models/operations_practice.dart';
import '../models/outfit_sentence.dart';
import '../models/phrase_building_state.dart';
import '../models/phrase_building_tile.dart';
import '../models/pending_completion.dart';
import '../models/play_outcome.dart';
import '../models/sentence.dart';
import '../models/sentence_composer_state.dart';
import '../models/sentence_quiz_state.dart';
import '../models/shopping_game.dart';
import '../models/spelling_quiz_state.dart';
import '../models/view_data.dart';
import '../services/gameplay_recorder.dart';
import '../services/game_content_factory.dart';
import 'conveyor_controller.dart';
import 'balance_game_controller.dart';
import 'crossword_controller.dart';
import 'even_odd_controller.dart';
import 'letter_catching_controller.dart';
import 'letter_dragging_controller.dart';
import 'letter_learning_controller.dart';
import 'letter_shooting_controller.dart';
import 'letter_practice_controller.dart';
import 'logic_game_controller.dart';
import 'memory_controller.dart';
import 'missing_letters_controller.dart';
import 'number_learning_controller.dart';
import 'number_comparison_controller.dart';
import 'number_dragging_controller.dart';
import 'number_memory_controller.dart';
import 'operator_conveyor_controller.dart';
import 'operations_practice_controller.dart';
import 'phrase_building_controller.dart';
import 'sentence_composer_controller.dart';
import 'sentence_quiz_controller.dart';
import 'shopping_game_controller.dart';
import 'spelling_quiz_controller.dart';

enum SessionStatus {
  opening,
  areaMenu,
  literacyMenu,
  mathMenu,
  mathPlaceholder,
  numberLearning,
  numberComparison,
  operationsPractice,
  numberDragging,
  numberMemory,
  balanceGame,
  logicGame,
  shoppingGame,
  operatorConveyor,
  evenOdd,
  letterLearning,
  letterPractice,
  phraseBuilding,
  letterDragging,
  missingLetters,
  letterShooting,
  memory,
  letterCatching,
  conveyor,
  sentenceQuiz,
  sentenceComposer,
  spellingQuiz,
  crossword,
  rating,
}

class SessionController extends ChangeNotifier {
  final AssetBundle _assetBundle;
  final AssetAudioPlayer _audioPlayer;
  final GameplayRecorder _gameplayRecorder;
  final GameContentFactory _gameContent;
  final DateTime Function() _now;
  final String _appVersion;
  final String _contentVersion;

  PhraseBuildingController? _phraseBuildingController;
  FeatureLoadError? _phraseBuildingError;
  LetterDraggingController? _letterDraggingController;
  FeatureLoadError? _letterDraggingError;
  LetterShootingController? _letterShootingController;
  FeatureLoadError? _letterShootingError;
  LetterCatchingController? _letterCatchingController;
  FeatureLoadError? _letterCatchingError;
  ConveyorController? _conveyorController;
  FeatureLoadError? _conveyorError;
  MissingLettersController? _missingLettersController;
  FeatureLoadError? _missingLettersError;
  MemoryController? _memoryController;
  FeatureLoadError? _memoryError;
  SpellingQuizController? _spellingQuizController;
  FeatureLoadError? _spellingQuizError;
  CrosswordController? _crosswordController;
  FeatureLoadError? _crosswordError;
  LetterLearningController? _letterLearningController;
  FeatureLoadError? _letterLearningError;
  LetterPracticeController? _letterPracticeController;
  FeatureLoadError? _letterPracticeError;
  bool _disposed = false;
  DateTime? _activityStartedAt;
  PendingCompletion? _pendingRating;
  ActivityId? _ratingActivity;
  late final SentenceQuizController _sentenceQuizController;
  late final SentenceComposerController _sentenceComposerController;
  late final NumberLearningController _numberLearningController;
  late final NumberComparisonController _numberComparisonController;
  late final OperationsPracticeController _operationsPracticeController;
  late final NumberDraggingController _numberDraggingController;
  late final NumberMemoryController _numberMemoryController;
  late final BalanceGameController _balanceGameController;
  late final LogicGameController _logicGameController;
  late final ShoppingGameController _shoppingGameController;
  late final OperatorConveyorController _operatorConveyorController;
  late final EvenOddController _evenOddController;
  SessionStatus status = SessionStatus.opening;
  int? mathPlaceholderNumber;

  SessionController({
    AssetBundle? assetBundle,
    AssetAudioPlayer? audioPlayer,
    GameplayRecorder gameplayRecorder = const NoopGameplayRecorder(),
    DateTime Function()? now,
    String appVersion = '0.1.0+1',
    String contentVersion = 'en-1',
    InterfaceLanguage language = InterfaceLanguage.english,
  }) : _assetBundle = assetBundle ?? rootBundle,
       _audioPlayer = audioPlayer ?? SoloudAssetAudioPlayer(),
       // Named public parameters keep dependency injection readable.
       // ignore: prefer_initializing_formals
       _gameplayRecorder = gameplayRecorder,
       _gameContent = GameContentFactory.forLanguage(language),
       _now = now ?? DateTime.now,
       // ignore: prefer_initializing_formals
       _appVersion = appVersion,
       // ignore: prefer_initializing_formals
       _contentVersion = contentVersion {
    _sentenceQuizController = SentenceQuizController(
      content: _gameContent.sentenceContent,
    )..addListener(_forwardFeatureNotification);
    _sentenceComposerController = SentenceComposerController(
      content: _gameContent.sentenceContent,
    )..addListener(_forwardFeatureNotification);
    _numberLearningController = NumberLearningController(_audioPlayer)
      ..addListener(_forwardFeatureNotification);
    _numberComparisonController = NumberComparisonController(_audioPlayer)
      ..addListener(_forwardFeatureNotification);
    _operationsPracticeController = OperationsPracticeController(_audioPlayer)
      ..addListener(_forwardFeatureNotification);
    _numberDraggingController = NumberDraggingController(_audioPlayer)
      ..addListener(_forwardFeatureNotification);
    _numberMemoryController = NumberMemoryController()
      ..addListener(_forwardFeatureNotification);
    _balanceGameController = BalanceGameController(_audioPlayer)
      ..addListener(_forwardFeatureNotification);
    _logicGameController = LogicGameController(_audioPlayer)
      ..addListener(_forwardFeatureNotification);
    _shoppingGameController = ShoppingGameController(_audioPlayer)
      ..addListener(_forwardFeatureNotification);
    _operatorConveyorController = OperatorConveyorController()
      ..addListener(_forwardFeatureNotification);
    _evenOddController = EvenOddController()
      ..addListener(_forwardFeatureNotification);
    unawaited(_gameplayRecorder.synchronize());
    unawaited(_initializePhraseBuilding());
    unawaited(_initializeLetterDragging());
    unawaited(_initializeLetterShooting());
    unawaited(_initializeLetterCatching());
    unawaited(_initializeConveyor());
    unawaited(_initializeMissingLetters());
    unawaited(_initializeMemory());
    unawaited(_initializeSpellingQuiz());
    unawaited(_initializeCrossword());
    unawaited(_initializeLetterLearning());
    unawaited(_initializeLetterPractice());
  }

  ActivityId get ratingActivity => _ratingActivity!;

  Future<void> submitRating(int rating) async {
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Must be between 1 and 5');
    }
    final completion = _pendingRating;
    if (completion == null) return;
    _pendingRating = null;
    _ratingActivity = null;
    _activityStartedAt = null;
    status = completion.area == LearningArea.math
        ? SessionStatus.mathMenu
        : SessionStatus.literacyMenu;
    notifyListeners();
    await _gameplayRecorder.recordCompleted(completion, rating);
  }

  late final List<(ActivityId, VoidCallback)> literacyMenuItems = [
    (ActivityId.letterLearning, openLetterLearning),
    (ActivityId.letterPractice, openLetterPractice),
    (ActivityId.phraseBuilding, openPhraseBuilding),
    (ActivityId.letterDragging, openLetterDragging),
    (ActivityId.missingLetters, openMissingLetters),
    (ActivityId.letterShooting, openLetterShooting),
    (ActivityId.memoryCards, openMemory),
    (ActivityId.letterCatching, openLetterCatching),
    (ActivityId.wordConveyor, openConveyor),
    (ActivityId.sentenceQuiz, openSentenceQuiz),
    (ActivityId.sentenceComposer, openSentenceComposer),
    (ActivityId.spellingQuiz, openSpellingQuiz),
    (ActivityId.crossword, openCrossword),
  ];

  late final List<(int, VoidCallback)> mathMenuItems = [
    (1, openNumberLearning),
    (2, openNumberComparison),
    (3, openOperationsPractice),
    (4, openNumberDragging),
    (5, openNumberMemory),
    (6, openBalanceGame),
    (7, openEvenOdd),
    (8, openOperatorConveyor),
    (9, openLogicGame),
    (10, openShoppingGame),
  ];

  NumberLearningViewData get numberLearningViewData => NumberLearningViewData(
    range: _numberLearningController.range,
    useColors: _numberLearningController.useColors,
    state: _numberLearningController.state,
    score: _numberLearningController.score,
    target: _numberLearningController.target,
    emoji: _numberLearningController.emoji,
    choices: _numberLearningController.choices,
    canGuess: _numberLearningController.canGuess,
    config: _numberLearningController.config,
  );

  void numberLearningSetRange(NumberRange value) =>
      _numberLearningController.setRange(value);
  void numberLearningSetUseColors(bool value) =>
      _numberLearningController.setUseColors(value);
  void numberLearningGuess(int number) {
    unawaited(_numberLearningController.guess(number));
  }

  void openNumberLearning() {
    _numberLearningController.start();
    _beginActivity(SessionStatus.numberLearning);
  }

  NumberComparisonViewData get numberComparisonViewData =>
      NumberComparisonViewData(
        range: _numberComparisonController.range,
        arrangement: _numberComparisonController.arrangement,
        state: _numberComparisonController.state,
        score: _numberComparisonController.score,
        leftNumber: _numberComparisonController.leftNumber,
        rightNumber: _numberComparisonController.rightNumber,
        leftEmoji: _numberComparisonController.leftEmoji,
        rightEmoji: _numberComparisonController.rightEmoji,
        leftPositions: _numberComparisonController.leftPositions,
        rightPositions: _numberComparisonController.rightPositions,
        canGuess: _numberComparisonController.canGuess,
        config: _numberComparisonController.config,
      );

  void numberComparisonSetRange(ComparisonRange value) =>
      _numberComparisonController.setRange(value);
  void numberComparisonSetArrangement(NumberArrangement value) =>
      _numberComparisonController.setArrangement(value);
  void numberComparisonGuess(NumberRelation relation) {
    unawaited(_numberComparisonController.guess(relation));
  }

  void openNumberComparison() {
    _numberComparisonController.start();
    _beginActivity(SessionStatus.numberComparison);
  }

  BalanceGameViewData get balanceGameViewData => BalanceGameViewData(
    state: _balanceGameController.state,
    score: _balanceGameController.score,
    incorrectAttempts: _balanceGameController.incorrectAttempts,
    exerciseId: _balanceGameController.exerciseId,
    goodsWeights: _balanceGameController.goodsWeights,
    shelfStones: _balanceGameController.shelfStones,
    selectedStones: _balanceGameController.selectedStones,
    canSelect: _balanceGameController.canSelect,
    leftTrayY: _balanceGameController.leftTrayY,
    rightTrayY: _balanceGameController.rightTrayY,
    handAngle: _balanceGameController.handAngle,
    config: _balanceGameController.config,
  );

  void balanceGameSelectStone(int stoneId) {
    unawaited(_balanceGameController.selectStone(stoneId));
  }

  LogicGameViewData get logicGameViewData => LogicGameViewData(
    difficulty: _logicGameController.difficulty,
    state: _logicGameController.state,
    score: _logicGameController.score,
    incorrectAttempts: _logicGameController.incorrectAttempts,
    objects: _logicGameController.objects,
    properties: _logicGameController.properties,
    placements: _logicGameController.placements,
    canPlace: _logicGameController.canPlace,
    config: _logicGameController.config,
  );

  void logicGameSetDifficulty(LogicDifficulty value) =>
      _logicGameController.setDifficulty(value);

  void logicGamePlace({
    required int objectId,
    required LogicPoint position,
    required double diagramWidth,
    required double diagramHeight,
  }) {
    unawaited(
      _logicGameController.place(
        objectId: objectId,
        position: position,
        diagramWidth: diagramWidth,
        diagramHeight: diagramHeight,
      ),
    );
  }

  OperationsPracticeViewData get operationsPracticeViewData =>
      OperationsPracticeViewData(
        operators: _operationsPracticeController.operators,
        range: _operationsPracticeController.range,
        useColors: _operationsPracticeController.useColors,
        state: _operationsPracticeController.state,
        score: _operationsPracticeController.score,
        equation: _operationsPracticeController.equation,
        choices: _operationsPracticeController.choices,
        canGuess: _operationsPracticeController.canGuess,
        config: _operationsPracticeController.config,
      );

  void operationsPracticeSetOperators(Set<ElementaryOperator> values) =>
      _operationsPracticeController.setOperators(values);
  void operationsPracticeSetRange(OperationsRange value) =>
      _operationsPracticeController.setRange(value);
  void operationsPracticeSetUseColors(bool value) =>
      _operationsPracticeController.setUseColors(value);
  void operationsPracticeGuess(int number) {
    unawaited(_operationsPracticeController.guess(number));
  }

  void openOperationsPractice() {
    _operationsPracticeController.start();
    _beginActivity(SessionStatus.operationsPractice);
  }

  NumberDraggingViewData get numberDraggingViewData => NumberDraggingViewData(
    tiles: _numberDraggingController.tiles,
    range: _numberDraggingController.range,
    state: _numberDraggingController.state,
    score: _numberDraggingController.score,
    countdown: _numberDraggingController.countdown.status,
  );

  void Function(int, int)? get numberDraggingReorder =>
      _numberDraggingController.canReorder
      ? _numberDraggingController.reorder
      : null;
  VoidCallback? get numberDraggingPass =>
      _numberDraggingController.canPass ? _numberDraggingController.pass : null;
  void numberDraggingSetRange(NumberDraggingRange value) =>
      _numberDraggingController.setRange(value);

  void openNumberDragging() {
    _numberDraggingController.start();
    _beginActivity(SessionStatus.numberDragging);
  }

  void restartNumberDragging() => _numberDraggingController.start();

  NumberMemoryViewData get numberMemoryViewData => NumberMemoryViewData(
    cards: _numberMemoryController.cards,
    range: _numberMemoryController.range,
    isComplete: _numberMemoryController.isComplete,
    config: _numberMemoryController.config,
  );
  Future<void> numberMemorySelect(int cardId) =>
      _numberMemoryController.select(cardId);
  void numberMemoryStartNewGame() => _numberMemoryController.startNewGame();
  void numberMemorySetRange(NumberMemoryRange value) =>
      _numberMemoryController.setRange(value);

  void openNumberMemory() {
    _numberMemoryController.startNewGame();
    _beginActivity(SessionStatus.numberMemory);
  }

  void openBalanceGame() {
    _balanceGameController.start();
    _beginActivity(SessionStatus.balanceGame);
  }

  void openLogicGame() {
    _logicGameController.start();
    _beginActivity(SessionStatus.logicGame);
  }

  void openShoppingGame() {
    _shoppingGameController.start();
    _beginActivity(SessionStatus.shoppingGame);
  }

  ShoppingGameViewData get shoppingGameViewData => ShoppingGameViewData(
    state: _shoppingGameController.state,
    score: _shoppingGameController.score,
    incorrectAttempts: _shoppingGameController.incorrectAttempts,
    cashRegisterState: _shoppingGameController.cashRegisterState,
    displayedGoods: _shoppingGameController.displayedGoods,
    payment: _shoppingGameController.payment,
    paymentIntroState: _shoppingGameController.paymentIntroState,
    canAnswerPayment: _shoppingGameController.canAnswerPayment,
    balanceNotes: _shoppingGameController.balanceNotes,
    balance: _shoppingGameController.balance,
    config: _shoppingGameController.config,
  );

  void shoppingGameToggleCashRegister() =>
      _shoppingGameController.toggleCashRegister();

  void shoppingGameAnswerNotEnough() =>
      _shoppingGameController.answerPayment(isEnough: false);

  void shoppingGameAnswerTakeBalance() =>
      _shoppingGameController.answerPayment(isEnough: true);

  void shoppingGameAddBalanceNote(int denominationIndex) =>
      _shoppingGameController.addBalanceNote(denominationIndex);

  void shoppingGameRemoveBalanceNote(int noteId) =>
      _shoppingGameController.removeBalanceNote(noteId);

  PhraseBuildingViewData get phraseBuildingViewData => PhraseBuildingViewData(
    isLoading:
        _phraseBuildingController == null && _phraseBuildingError == null,
    loadError: _phraseBuildingError,
    sourcePool: _phraseBuildingController?.sourcePool ?? const [],
    targetPool: _phraseBuildingController?.targetPool ?? const [],
    state: _phraseBuildingController?.state ?? PhraseBuildingState.guessing,
    score: _phraseBuildingController?.score ?? 0,
  );

  void Function(PhraseBuildingTile)? get phraseBuildingMove {
    final controller = _phraseBuildingController;
    return controller != null && controller.canMove ? controller.move : null;
  }

  bool phraseBuildingCanMoveToTarget(PhraseBuildingTile tile) =>
      _phraseBuildingController?.canMoveToTarget(tile) ?? false;
  bool phraseBuildingCanMoveToSource(PhraseBuildingTile tile) =>
      _phraseBuildingController?.canMoveToSource(tile) ?? false;
  void phraseBuildingMoveToTarget(PhraseBuildingTile tile) =>
      _phraseBuildingController?.moveToTarget(tile);
  void phraseBuildingMoveToSource(PhraseBuildingTile tile) =>
      _phraseBuildingController?.moveToSource(tile);

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
    _beginActivity(SessionStatus.phraseBuilding);
    unawaited(_phraseBuildingController?.playAudio());
  }

  void restartPhraseBuilding() {
    _phraseBuildingController?.start();
    unawaited(_phraseBuildingController?.playAudio());
  }

  LetterDraggingViewData get letterDraggingViewData => LetterDraggingViewData(
    isLoading:
        _letterDraggingController == null && _letterDraggingError == null,
    loadError: _letterDraggingError,
    tiles: _letterDraggingController?.tiles ?? const [],
    state: _letterDraggingController?.state ?? LetterDraggingState.playing,
    score: _letterDraggingController?.score ?? 0,
    countdown: _letterDraggingController?.countdown.status,
    imagePath: _letterDraggingController?.imagePath,
    showImages: _letterDraggingController?.showImages ?? true,
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

  void letterDraggingSetShowImages(bool value) =>
      _letterDraggingController?.setShowImages(value);

  void openLetterDragging() {
    _letterDraggingController?.start();
    _beginActivity(SessionStatus.letterDragging);
  }

  void restartLetterDragging() => _letterDraggingController?.start();

  LetterShootingViewData get letterShootingViewData => LetterShootingViewData(
    isLoading:
        _letterShootingController == null && _letterShootingError == null,
    loadError: _letterShootingError,
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
    _beginActivity(SessionStatus.letterShooting);
  }

  void restartLetterShooting() => _letterShootingController?.start();

  LetterCatchingViewData get letterCatchingViewData => LetterCatchingViewData(
    isLoading:
        _letterCatchingController == null && _letterCatchingError == null,
    loadError: _letterCatchingError,
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
    _beginActivity(SessionStatus.letterCatching);
  }

  void restartLetterCatching() => _letterCatchingController?.start();

  EvenOddViewData get evenOddViewData => EvenOddViewData(
    world: _evenOddController.world,
    state: _evenOddController.state,
  );
  void evenOddResize(double width, double height) =>
      _evenOddController.resize(width, height);
  void evenOddTick(double deltaSeconds) =>
      _evenOddController.tick(deltaSeconds);
  void evenOddMovePaddleBy(double deltaX) =>
      _evenOddController.movePaddleBy(deltaX);
  void evenOddToggleParity() => _evenOddController.toggleParity();

  void openEvenOdd() {
    _evenOddController.start();
    _beginActivity(SessionStatus.evenOdd);
  }

  void restartEvenOdd() => _evenOddController.start();

  ConveyorViewData get conveyorViewData => ConveyorViewData(
    isLoading: _conveyorController == null && _conveyorError == null,
    loadError: _conveyorError,
    world: _conveyorController?.world,
    state: _conveyorController?.state ?? ConveyorState.playing,
    selectedLetterId: _conveyorController?.selectedLetterId,
    difficulty: _conveyorController?.difficulty ?? ConveyorDifficulty.easy,
  );

  void conveyorSetDifficulty(ConveyorDifficulty value) =>
      _conveyorController?.setDifficulty(value);

  void conveyorResize(double width, double height) =>
      _conveyorController?.resize(width, height);
  ConveyorState conveyorTick(double deltaSeconds) =>
      _conveyorController?.tick(deltaSeconds) ?? ConveyorState.playing;
  bool conveyorCanAccept({required int letterId, required int shelfId}) =>
      _conveyorController?.canAccept(letterId: letterId, shelfId: shelfId) ??
      false;
  void conveyorStartDragging(int letterId) =>
      _conveyorController?.startDragging(letterId);
  void conveyorSelectLetter(int letterId) =>
      _conveyorController?.selectLetter(letterId);
  void conveyorPlaceSelected(int shelfId) =>
      _conveyorController?.placeSelected(shelfId);
  void conveyorCancelDragging(int letterId) =>
      _conveyorController?.cancelDragging(letterId);
  void conveyorDrop({required int letterId, required int shelfId}) =>
      _conveyorController?.drop(letterId: letterId, shelfId: shelfId);

  void openConveyor() {
    _conveyorController?.start();
    _beginActivity(SessionStatus.conveyor);
  }

  void restartConveyor() => _conveyorController?.start();

  OperatorConveyorViewData get operatorConveyorViewData =>
      OperatorConveyorViewData(
        world: _operatorConveyorController.world,
        state: _operatorConveyorController.state,
        selectedOperatorId: _operatorConveyorController.selectedOperatorId,
        difficulty: _operatorConveyorController.difficulty,
      );
  void operatorConveyorSetDifficulty(ConveyorDifficulty value) =>
      _operatorConveyorController.setDifficulty(value);
  void operatorConveyorResize(double width, double height) =>
      _operatorConveyorController.resize(width, height);
  ConveyorState operatorConveyorTick(double deltaSeconds) =>
      _operatorConveyorController.tick(deltaSeconds);
  bool operatorConveyorCanAccept({
    required int operatorId,
    required int shelfId,
  }) => _operatorConveyorController.canAccept(
    operatorId: operatorId,
    shelfId: shelfId,
  );
  void operatorConveyorStartDragging(int operatorId) =>
      _operatorConveyorController.startDragging(operatorId);
  void operatorConveyorSelectOperator(int operatorId) =>
      _operatorConveyorController.selectOperator(operatorId);
  void operatorConveyorPlaceSelected(int shelfId) =>
      _operatorConveyorController.placeSelected(shelfId);
  void operatorConveyorCancelDragging(int operatorId) =>
      _operatorConveyorController.cancelDragging(operatorId);
  void operatorConveyorDrop({required int operatorId, required int shelfId}) =>
      _operatorConveyorController.drop(
        operatorId: operatorId,
        shelfId: shelfId,
      );

  void openOperatorConveyor() {
    _operatorConveyorController.start();
    _beginActivity(SessionStatus.operatorConveyor);
  }

  void restartOperatorConveyor() => _operatorConveyorController.start();

  SentenceQuizViewData get sentenceQuizViewData => SentenceQuizViewData(
    question: _sentenceQuizController.question,
    optionTexts: _sentenceQuizController.optionTexts,
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
    _beginActivity(SessionStatus.sentenceQuiz);
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
        personLabels: {
          for (final person in SentencePerson.values)
            person: _sentenceComposerController.content.personName(person),
        },
        colorLabels: {
          for (final color in GarmentColor.values)
            color: _sentenceComposerController.content.colorName(color),
        },
        pieceLabels: {
          for (final piece in ClothingPiece.values)
            piece: _sentenceComposerController.content.pieceName(piece),
        },
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
    _beginActivity(SessionStatus.sentenceComposer);
  }

  void restartSentenceComposer() => _sentenceComposerController.start();

  SpellingQuizViewData get spellingQuizViewData => SpellingQuizViewData(
    isLoading: _spellingQuizController == null && _spellingQuizError == null,
    loadError: _spellingQuizError,
    question: _spellingQuizController?.question,
    state: _spellingQuizController?.state ?? SpellingQuizState.guessing,
    score: _spellingQuizController?.score ?? 0,
    correctHighlightIndex: _spellingQuizController?.correctHighlightIndex,
    wrongHighlightIndex: _spellingQuizController?.wrongHighlightIndex,
    canSubmit: _spellingQuizController?.canSubmit ?? false,
  );

  Future<void> spellingQuizSubmit(int guessIndex) =>
      _spellingQuizController?.submit(guessIndex) ?? Future.value();
  Future<void> spellingQuizPlayAudio() =>
      _spellingQuizController?.playAudio() ?? Future.value();

  void openSpellingQuiz() {
    _spellingQuizController?.start();
    _beginActivity(SessionStatus.spellingQuiz);
    unawaited(_spellingQuizController?.playAudio());
  }

  void restartSpellingQuiz() {
    _spellingQuizController?.start();
    unawaited(_spellingQuizController?.playAudio());
  }

  CrosswordViewData get crosswordViewData => CrosswordViewData(
    isLoading: _crosswordController == null && _crosswordError == null,
    loadError: _crosswordError,
    puzzle: _crosswordController?.puzzle,
    config: _crosswordController?.config ?? crosswordConfig,
    state: _crosswordController?.state ?? CrosswordState.playing,
    score: _crosswordController?.score ?? 0,
    selectedLetter: _crosswordController?.selectedLetter,
  );

  void crosswordSelectLetter(String letter) =>
      _crosswordController?.selectLetter(letter);
  bool crosswordCanPlace({required int cellId, required String letter}) =>
      _crosswordController?.canPlace(cellId: cellId, letter: letter) ?? false;
  Future<void> crosswordPlaceSelected(int cellId) =>
      _crosswordController?.placeSelected(cellId) ?? Future.value();
  Future<void> crosswordPlace({required int cellId, required String letter}) =>
      _crosswordController?.place(cellId: cellId, letter: letter) ??
      Future.value();

  void openCrossword() {
    _crosswordController?.start();
    _beginActivity(SessionStatus.crossword);
  }

  void restartCrossword() => _crosswordController?.start();

  LetterLearningViewData get letterLearningViewData => LetterLearningViewData(
    isLoading:
        _letterLearningController == null && _letterLearningError == null,
    loadError: _letterLearningError,
    currentLetter: _letterLearningController?.currentLetter,
    currentObject: _letterLearningController?.currentObject,
    slots: _letterLearningController?.slots ?? const [],
    sourceLetters: _letterLearningController?.sourceLetters ?? const [],
    availableTiers:
        _letterLearningController?.availableTiers ?? const [1, 2, 3],
    tiers: _letterLearningController?.tiers ?? const {1},
    mode: _letterLearningController?.mode ?? LetterLearningMode.masked,
    state: _letterLearningController?.state ?? LetterLearningState.playing,
    score: _letterLearningController?.score ?? 0,
    sourceColumnCount: _letterLearningController?.sourceColumnCount ?? 5,
    config: _letterLearningController?.config ?? letterLearningConfig,
    canGuess: _letterLearningController?.canGuess ?? false,
    isTargetRevealed: _letterLearningController?.isTargetRevealed ?? false,
    selectedLetter: _letterLearningController?.selectedLetter,
  );

  void letterLearningSetTiers(Set<int> values) =>
      _letterLearningController?.setTiers(values);
  void letterLearningSetMode(LetterLearningMode value) =>
      _letterLearningController?.setMode(value);
  void letterLearningGuess(String letter) {
    unawaited(_letterLearningController?.guess(letter));
  }

  void letterLearningSelectLetter(String letter) =>
      _letterLearningController?.selectLetter(letter);
  void letterLearningGuessSelected() {
    unawaited(_letterLearningController?.guessSelected());
  }

  Future<void> letterLearningPlayAudio() =>
      _letterLearningController?.playPrompt() ?? Future.value();

  void openLetterLearning() {
    _letterLearningController?.start();
    _beginActivity(SessionStatus.letterLearning);
    unawaited(_letterLearningController?.playPrompt());
  }

  void restartLetterLearning() {
    _letterLearningController?.start();
    unawaited(_letterLearningController?.playPrompt());
  }

  LetterPracticeViewData get letterPracticeViewData => LetterPracticeViewData(
    isLoading:
        _letterPracticeController == null && _letterPracticeError == null,
    loadError: _letterPracticeError,
    currentWord: _letterPracticeController?.currentWord,
    slots: _letterPracticeController?.slots ?? const [],
    sourceLetters: _letterPracticeController?.sourceLetters ?? const [],
    availableTiers:
        _letterPracticeController?.availableTiers ?? const [1, 2, 3],
    tiers: _letterPracticeController?.tiers ?? const {1},
    wordSet:
        _letterPracticeController?.wordSet ?? LetterPracticeWordSet.alphabet,
    useColors: _letterPracticeController?.useColors ?? true,
    selectedLetter: _letterPracticeController?.selectedLetter,
    sourceColumnCount: _letterPracticeController?.sourceColumnCount ?? 5,
    score: _letterPracticeController?.score ?? 0,
    state: _letterPracticeController?.state ?? LetterPracticeState.playing,
    config: _letterPracticeController?.config ?? letterPracticeConfig,
    canPlay: _letterPracticeController?.canPlay ?? false,
  );

  void letterPracticeSetTiers(Set<int> values) =>
      _letterPracticeController?.setTiers(values);
  void letterPracticeSetWordSet(LetterPracticeWordSet value) =>
      _letterPracticeController?.setWordSet(value);
  void letterPracticeSetUseColors(bool value) =>
      _letterPracticeController?.setUseColors(value);
  void letterPracticeSelectLetter(String letter) =>
      _letterPracticeController?.selectLetter(letter);
  bool letterPracticeCanPlace({required int slotId, required String letter}) =>
      _letterPracticeController?.canPlace(slotId: slotId, letter: letter) ??
      false;
  Future<void> letterPracticePlaceSelected(int slotId) =>
      _letterPracticeController?.placeSelected(slotId) ?? Future.value();
  Future<void> letterPracticePlace({
    required int slotId,
    required String letter,
  }) =>
      _letterPracticeController?.place(slotId: slotId, letter: letter) ??
      Future.value();
  Future<void> letterPracticePlayAudio() =>
      _letterPracticeController?.playAudio() ?? Future.value();

  void openLetterPractice() {
    _letterPracticeController?.start();
    _beginActivity(SessionStatus.letterPractice);
    unawaited(_letterPracticeController?.playAudio());
  }

  void restartLetterPractice() {
    _letterPracticeController?.start();
    unawaited(_letterPracticeController?.playAudio());
  }

  MissingLettersViewData get missingLettersViewData => MissingLettersViewData(
    isLoading:
        _missingLettersController == null && _missingLettersError == null,
    loadError: _missingLettersError,
    slots: _missingLettersController?.slots ?? const [],
    pool: _missingLettersController?.pool ?? const [],
    state: _missingLettersController?.state ?? MissingLettersState.solving,
    score: _missingLettersController?.score ?? 0,
    selectedTileId: _missingLettersController?.selectedTileId,
    imagePath: _missingLettersController?.imagePath,
    showImages: _missingLettersController?.showImages ?? true,
  );
  void missingLettersSetShowImages(bool value) =>
      _missingLettersController?.setShowImages(value);

  bool missingLettersCanDrop({required int targetId, required int tileId}) =>
      _missingLettersController?.canDrop(targetId: targetId, tileId: tileId) ??
      false;

  void missingLettersDrop({required int targetId, required int tileId}) =>
      _missingLettersController?.drop(targetId: targetId, tileId: tileId);
  void missingLettersSelectTile(int tileId) =>
      _missingLettersController?.selectTile(tileId);
  void missingLettersPlaceSelected(int targetId) =>
      _missingLettersController?.placeSelected(targetId);

  void openMissingLetters() {
    _missingLettersController?.start();
    _beginActivity(SessionStatus.missingLetters);
  }

  void restartMissingLetters() => _missingLettersController?.start();

  MemoryViewData get memoryViewData => MemoryViewData(
    isLoading: _memoryController == null && _memoryError == null,
    loadError: _memoryError,
    cards: _memoryController?.cards ?? const [],
    isComplete: _memoryController?.isComplete ?? false,
    config: _memoryController?.config ?? memoryConfig,
  );
  Future<void> memorySelect(int cardId) =>
      _memoryController?.select(cardId) ?? Future.value();
  void memoryStartNewGame() => _memoryController?.startNewGame();

  void openMemory() {
    _memoryController?.startNewGame();
    _beginActivity(SessionStatus.memory);
  }

  AnswerFeedback _answerFeedback(ComposerChoiceAssessment assessment) =>
      switch (assessment) {
        ComposerChoiceAssessment.neutral => AnswerFeedback.neutral,
        ComposerChoiceAssessment.correct => AnswerFeedback.correct,
        ComposerChoiceAssessment.wrong => AnswerFeedback.wrong,
      };

  void openAreaMenu() {
    mathPlaceholderNumber = null;
    _open(SessionStatus.areaMenu);
  }

  bool get canExitAccount => status != SessionStatus.rating;

  void exitAccount() {
    if (!canExitAccount) return;
    _leaveActivity(SessionStatus.areaMenu);
  }

  void openMathMenu() {
    mathPlaceholderNumber = null;
    _leaveActivity(SessionStatus.mathMenu);
  }

  void openMathPlaceholder(int number) {
    if (number < 1 || number > 8) {
      throw ArgumentError.value(number, 'number', 'Must be between 1 and 8');
    }
    mathPlaceholderNumber = number;
    _open(SessionStatus.mathPlaceholder);
  }

  void openLiteracyMenu() {
    _leaveActivity(SessionStatus.literacyMenu);
  }

  void _leaveActivity(SessionStatus destination) {
    final currentStatus = status;
    if (_isActivity(currentStatus) && _activityStartedAt != null) {
      final abandoned = _buildCompletion(currentStatus, PlayOutcome.abandoned);
      unawaited(_gameplayRecorder.recordAbandoned(abandoned));
    }
    _activityStartedAt = null;
    _pendingRating = null;
    _ratingActivity = null;
    unawaited(_audioPlayer.stop());
    _phraseBuildingController?.stop();
    _letterDraggingController?.stop();
    _letterShootingController?.stop();
    _letterCatchingController?.stop();
    _conveyorController?.stop();
    _memoryController?.stop();
    _sentenceQuizController.stop();
    _sentenceComposerController.stop();
    _spellingQuizController?.stop();
    _crosswordController?.stop();
    _letterLearningController?.stop();
    _letterPracticeController?.stop();
    _numberLearningController.stop();
    _numberComparisonController.stop();
    _operationsPracticeController.stop();
    _numberDraggingController.stop();
    _numberMemoryController.stop();
    _balanceGameController.stop();
    _logicGameController.stop();
    _shoppingGameController.stop();
    _operatorConveyorController.stop();
    _evenOddController.stop();
    _open(destination);
  }

  void handleBack() {
    switch (status) {
      case SessionStatus.opening:
      case SessionStatus.rating:
        return;
      case SessionStatus.areaMenu:
        _open(SessionStatus.opening);
      case SessionStatus.literacyMenu:
      case SessionStatus.mathMenu:
        openAreaMenu();
      case SessionStatus.mathPlaceholder:
        openMathMenu();
      default:
        _activityFor(status).area == LearningArea.math
            ? openMathMenu()
            : openLiteracyMenu();
    }
  }

  void _beginActivity(SessionStatus activity) {
    _activityStartedAt = _now();
    _pendingRating = null;
    _ratingActivity = null;
    _open(activity);
  }

  bool _isActivity(SessionStatus value) => switch (value) {
    SessionStatus.letterLearning ||
    SessionStatus.letterPractice ||
    SessionStatus.phraseBuilding ||
    SessionStatus.letterDragging ||
    SessionStatus.missingLetters ||
    SessionStatus.letterShooting ||
    SessionStatus.memory ||
    SessionStatus.letterCatching ||
    SessionStatus.conveyor ||
    SessionStatus.sentenceQuiz ||
    SessionStatus.sentenceComposer ||
    SessionStatus.spellingQuiz ||
    SessionStatus.crossword => true,
    SessionStatus.numberLearning => true,
    SessionStatus.numberComparison => true,
    SessionStatus.operationsPractice => true,
    SessionStatus.numberDragging => true,
    SessionStatus.numberMemory => true,
    SessionStatus.balanceGame => true,
    SessionStatus.logicGame => true,
    SessionStatus.shoppingGame => true,
    SessionStatus.operatorConveyor => true,
    SessionStatus.evenOdd => true,
    _ => false,
  };

  bool _isTerminal(SessionStatus value) => switch (value) {
    SessionStatus.letterLearning =>
      _letterLearningController?.state == LetterLearningState.won,
    SessionStatus.letterPractice =>
      _letterPracticeController?.state == LetterPracticeState.won,
    SessionStatus.phraseBuilding =>
      _phraseBuildingController?.state == PhraseBuildingState.won,
    SessionStatus.letterDragging =>
      _letterDraggingController?.state == LetterDraggingState.result,
    SessionStatus.missingLetters =>
      _missingLettersController?.state == MissingLettersState.won,
    SessionStatus.letterShooting =>
      _letterShootingController?.state == LetterShootingState.ended,
    SessionStatus.memory => _memoryController?.isComplete ?? false,
    SessionStatus.letterCatching =>
      _letterCatchingController?.state != LetterCatchingState.playing,
    SessionStatus.conveyor =>
      _conveyorController?.state != ConveyorState.playing,
    SessionStatus.sentenceQuiz =>
      _sentenceQuizController.state == SentenceQuizState.won,
    SessionStatus.sentenceComposer =>
      _sentenceComposerController.state == SentenceComposerState.won,
    SessionStatus.spellingQuiz =>
      _spellingQuizController?.state == SpellingQuizState.won,
    SessionStatus.crossword =>
      _crosswordController?.state == CrosswordState.won,
    SessionStatus.numberLearning =>
      _numberLearningController.state == NumberLearningState.won,
    SessionStatus.numberComparison =>
      _numberComparisonController.state == NumberComparisonState.won,
    SessionStatus.operationsPractice =>
      _operationsPracticeController.state == OperationsPracticeState.won,
    SessionStatus.numberDragging =>
      _numberDraggingController.state == LetterDraggingState.result,
    SessionStatus.numberMemory => _numberMemoryController.isComplete,
    SessionStatus.balanceGame =>
      _balanceGameController.state == BalanceGameState.won,
    SessionStatus.logicGame => _logicGameController.state == LogicGameState.won,
    SessionStatus.shoppingGame =>
      _shoppingGameController.state == ShoppingGameState.won,
    SessionStatus.operatorConveyor =>
      _operatorConveyorController.state != ConveyorState.playing,
    SessionStatus.evenOdd =>
      _evenOddController.state != LetterCatchingState.playing,
    SessionStatus.opening ||
    SessionStatus.areaMenu ||
    SessionStatus.literacyMenu ||
    SessionStatus.mathMenu ||
    SessionStatus.mathPlaceholder ||
    SessionStatus.rating => false,
  };

  PlayOutcome _terminalOutcome(SessionStatus value) => switch (value) {
    SessionStatus.letterDragging ||
    SessionStatus.numberDragging ||
    SessionStatus.memory ||
    SessionStatus.numberMemory => PlayOutcome.completed,
    SessionStatus.letterCatching =>
      _letterCatchingController?.state == LetterCatchingState.lost
          ? PlayOutcome.lost
          : PlayOutcome.won,
    SessionStatus.conveyor =>
      _conveyorController?.state == ConveyorState.lost
          ? PlayOutcome.lost
          : PlayOutcome.won,
    SessionStatus.operatorConveyor =>
      _operatorConveyorController.state == ConveyorState.lost
          ? PlayOutcome.lost
          : PlayOutcome.won,
    SessionStatus.evenOdd =>
      _evenOddController.state == LetterCatchingState.lost
          ? PlayOutcome.lost
          : PlayOutcome.won,
    SessionStatus.opening ||
    SessionStatus.areaMenu ||
    SessionStatus.literacyMenu ||
    SessionStatus.mathMenu ||
    SessionStatus.mathPlaceholder ||
    SessionStatus.rating => throw StateError(
      'A non-gameplay status cannot finish.',
    ),
    _ => PlayOutcome.won,
  };

  ActivityId _activityFor(SessionStatus value) => switch (value) {
    SessionStatus.letterLearning => ActivityId.letterLearning,
    SessionStatus.letterPractice => ActivityId.letterPractice,
    SessionStatus.phraseBuilding => ActivityId.phraseBuilding,
    SessionStatus.letterDragging => ActivityId.letterDragging,
    SessionStatus.missingLetters => ActivityId.missingLetters,
    SessionStatus.letterShooting => ActivityId.letterShooting,
    SessionStatus.memory => ActivityId.memoryCards,
    SessionStatus.letterCatching => ActivityId.letterCatching,
    SessionStatus.conveyor => ActivityId.wordConveyor,
    SessionStatus.sentenceQuiz => ActivityId.sentenceQuiz,
    SessionStatus.sentenceComposer => ActivityId.sentenceComposer,
    SessionStatus.spellingQuiz => ActivityId.spellingQuiz,
    SessionStatus.crossword => ActivityId.crossword,
    SessionStatus.numberLearning => ActivityId.numberLearning,
    SessionStatus.numberComparison => ActivityId.numberComparison,
    SessionStatus.operationsPractice => ActivityId.operationsPractice,
    SessionStatus.numberDragging => ActivityId.numberDragging,
    SessionStatus.numberMemory => ActivityId.numberMemory,
    SessionStatus.balanceGame => ActivityId.balanceGame,
    SessionStatus.logicGame => ActivityId.logicGame,
    SessionStatus.shoppingGame => ActivityId.shoppingGame,
    SessionStatus.operatorConveyor => ActivityId.operatorConveyor,
    SessionStatus.evenOdd => ActivityId.evenOdd,
    SessionStatus.opening ||
    SessionStatus.areaMenu ||
    SessionStatus.literacyMenu ||
    SessionStatus.mathMenu ||
    SessionStatus.mathPlaceholder ||
    SessionStatus.rating => throw StateError(
      'A non-gameplay status has no activity.',
    ),
  };

  int? _scoreFor(SessionStatus value) => switch (value) {
    SessionStatus.letterLearning => _letterLearningController?.score ?? 0,
    SessionStatus.letterPractice => _letterPracticeController?.score ?? 0,
    SessionStatus.phraseBuilding => _phraseBuildingController?.score ?? 0,
    SessionStatus.letterDragging => _letterDraggingController?.score ?? 0,
    SessionStatus.missingLetters => _missingLettersController?.score ?? 0,
    SessionStatus.letterShooting => _letterShootingController?.world.score ?? 0,
    SessionStatus.memory => null,
    SessionStatus.letterCatching => _letterCatchingController?.world.score ?? 0,
    SessionStatus.conveyor => _conveyorController?.world.score ?? 0,
    SessionStatus.sentenceQuiz => _sentenceQuizController.score,
    SessionStatus.sentenceComposer => _sentenceComposerController.score,
    SessionStatus.spellingQuiz => _spellingQuizController?.score ?? 0,
    SessionStatus.crossword => _crosswordController?.score ?? 0,
    SessionStatus.numberLearning => _numberLearningController.score,
    SessionStatus.numberComparison => _numberComparisonController.score,
    SessionStatus.operationsPractice => _operationsPracticeController.score,
    SessionStatus.numberDragging => _numberDraggingController.score,
    SessionStatus.numberMemory => null,
    SessionStatus.balanceGame => _balanceGameController.score,
    SessionStatus.logicGame => _logicGameController.score,
    SessionStatus.shoppingGame => _shoppingGameController.score,
    SessionStatus.operatorConveyor => _operatorConveyorController.world.score,
    SessionStatus.evenOdd => _evenOddController.world.score,
    SessionStatus.opening ||
    SessionStatus.areaMenu ||
    SessionStatus.literacyMenu ||
    SessionStatus.mathMenu ||
    SessionStatus.mathPlaceholder ||
    SessionStatus.rating => null,
  };

  FeatureMetrics _metricsFor(SessionStatus value) => switch (value) {
    SessionStatus.letterDragging => TimedWordMetrics(
      correctAnswers: _letterDraggingController?.score ?? 0,
      passedItems: _letterDraggingController?.passedItems ?? 0,
    ),
    SessionStatus.numberDragging => TimedWordMetrics(
      correctAnswers: _numberDraggingController.score,
      passedItems: _numberDraggingController.passedItems,
    ),
    SessionStatus.memory => MemoryMetrics(
      pairCount: _memoryController?.config.pairCount ?? memoryConfig.pairCount,
      pairAttempts: _memoryController?.pairAttempts ?? 0,
      mismatches: _memoryController?.mismatches ?? 0,
    ),
    SessionStatus.numberMemory => MemoryMetrics(
      pairCount: _numberMemoryController.config.pairCount,
      pairAttempts: _numberMemoryController.pairAttempts,
      mismatches: _numberMemoryController.mismatches,
    ),
    SessionStatus.balanceGame => AttemptMetrics(
      correctAnswers: _balanceGameController.score,
      incorrectAttempts: _balanceGameController.incorrectAttempts,
    ),
    SessionStatus.logicGame => AttemptMetrics(
      correctAnswers: _logicGameController.score,
      incorrectAttempts: _logicGameController.incorrectAttempts,
    ),
    SessionStatus.shoppingGame => AttemptMetrics(
      correctAnswers: _shoppingGameController.score,
      incorrectAttempts: _shoppingGameController.incorrectAttempts,
    ),
    SessionStatus.letterCatching => LivesMetrics(
      correctAnswers: _letterCatchingController?.world.score ?? 0,
      incorrectAttempts:
          (_letterCatchingController?.world.config.startingLives ??
              letterCatchingConfig.startingLives) -
          (_letterCatchingController?.world.lives ??
              letterCatchingConfig.startingLives),
      startingLives:
          _letterCatchingController?.world.config.startingLives ??
          letterCatchingConfig.startingLives,
      remainingLives:
          _letterCatchingController?.world.lives ??
          letterCatchingConfig.startingLives,
    ),
    SessionStatus.conveyor => LivesMetrics(
      correctAnswers: _conveyorController?.world.score ?? 0,
      incorrectAttempts:
          (_conveyorController?.world.config.startingLives ??
              conveyorConfig.startingLives) -
          (_conveyorController?.world.lives ?? conveyorConfig.startingLives),
      startingLives:
          _conveyorController?.world.config.startingLives ??
          conveyorConfig.startingLives,
      remainingLives:
          _conveyorController?.world.lives ?? conveyorConfig.startingLives,
    ),
    SessionStatus.letterLearning => AttemptMetrics(
      correctAnswers: _letterLearningController?.score ?? 0,
      incorrectAttempts: _letterLearningController?.incorrectAttempts ?? 0,
    ),
    SessionStatus.letterPractice => AttemptMetrics(
      correctAnswers: _letterPracticeController?.score ?? 0,
      incorrectAttempts: _letterPracticeController?.incorrectAttempts ?? 0,
    ),
    SessionStatus.phraseBuilding => AttemptMetrics(
      correctAnswers: _phraseBuildingController?.score ?? 0,
      incorrectAttempts: _phraseBuildingController?.incorrectAttempts ?? 0,
    ),
    SessionStatus.missingLetters => AttemptMetrics(
      correctAnswers: _missingLettersController?.score ?? 0,
      incorrectAttempts: _missingLettersController?.incorrectAttempts ?? 0,
    ),
    SessionStatus.letterShooting => AttemptMetrics(
      correctAnswers: _letterShootingController?.world.score ?? 0,
      incorrectAttempts:
          _letterShootingController?.world.incorrectAttempts ?? 0,
    ),
    SessionStatus.sentenceQuiz => AttemptMetrics(
      correctAnswers: _sentenceQuizController.score,
      incorrectAttempts: _sentenceQuizController.incorrectAttempts,
    ),
    SessionStatus.sentenceComposer => AttemptMetrics(
      correctAnswers: _sentenceComposerController.score,
      incorrectAttempts: _sentenceComposerController.incorrectAttempts,
    ),
    SessionStatus.spellingQuiz => AttemptMetrics(
      correctAnswers: _spellingQuizController?.score ?? 0,
      incorrectAttempts: _spellingQuizController?.incorrectAttempts ?? 0,
    ),
    SessionStatus.crossword => AttemptMetrics(
      correctAnswers: _crosswordController?.score ?? 0,
      incorrectAttempts: _crosswordController?.incorrectAttempts ?? 0,
    ),
    SessionStatus.numberLearning => AttemptMetrics(
      correctAnswers: _numberLearningController.score,
      incorrectAttempts: _numberLearningController.incorrectAttempts,
    ),
    SessionStatus.numberComparison => AttemptMetrics(
      correctAnswers: _numberComparisonController.score,
      incorrectAttempts: _numberComparisonController.incorrectAttempts,
    ),
    SessionStatus.operationsPractice => AttemptMetrics(
      correctAnswers: _operationsPracticeController.score,
      incorrectAttempts: _operationsPracticeController.incorrectAttempts,
    ),
    SessionStatus.operatorConveyor => LivesMetrics(
      correctAnswers: _operatorConveyorController.world.score,
      incorrectAttempts:
          _operatorConveyorController.world.config.startingLives -
          _operatorConveyorController.world.lives,
      startingLives: _operatorConveyorController.world.config.startingLives,
      remainingLives: _operatorConveyorController.world.lives,
    ),
    SessionStatus.evenOdd => LivesMetrics(
      correctAnswers: _evenOddController.world.score,
      incorrectAttempts:
          _evenOddController.world.config.startingLives -
          _evenOddController.world.lives,
      startingLives: _evenOddController.world.config.startingLives,
      remainingLives: _evenOddController.world.lives,
    ),
    SessionStatus.opening ||
    SessionStatus.areaMenu ||
    SessionStatus.literacyMenu ||
    SessionStatus.mathMenu ||
    SessionStatus.mathPlaceholder ||
    SessionStatus.rating => throw StateError(
      'A non-gameplay status has no metrics.',
    ),
  };

  PendingCompletion _buildCompletion(
    SessionStatus activity,
    PlayOutcome outcome,
  ) {
    final startedAt = _activityStartedAt;
    if (startedAt == null) throw StateError('No activity is being tracked.');
    final completedAt = _now();
    return PendingCompletion(
      area: _activityFor(activity).area,
      feature: _activityFor(activity),
      outcome: outcome,
      score: _scoreFor(activity),
      metrics: _metricsFor(activity),
      startedAt: startedAt,
      completedAt: completedAt,
      elapsedMilliseconds: completedAt.difference(startedAt).inMilliseconds,
      appVersion: _appVersion,
      contentVersion: _gameContent.contentVersionFor(
        _activityFor(activity),
        _contentVersion,
      ),
    );
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
      if (status == SessionStatus.phraseBuilding) {
        _phraseBuildingController!.start();
        unawaited(_phraseBuildingController!.playAudio());
      }
    } catch (_) {
      if (_disposed) return;
      _phraseBuildingError = FeatureLoadError.phraseBuilding;
    }
    notifyListeners();
  }

  Future<void> _initializeLetterDragging() async {
    try {
      final encoded = await _assetBundle.loadString(
        _gameContent.localizedAnimalWordsPath,
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
      _letterDraggingError = FeatureLoadError.letterDragging;
    }
    notifyListeners();
  }

  Future<void> _initializeMissingLetters() async {
    try {
      final encoded = await _assetBundle.loadString(
        _gameContent.localizedAnimalWordsPath,
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
      _missingLettersError = FeatureLoadError.missingLetters;
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
      _letterShootingError = FeatureLoadError.letterShooting;
    }
    notifyListeners();
  }

  Future<void> _initializeLetterCatching() async {
    try {
      final encoded = await _assetBundle.loadString(
        _gameContent.localizedAnimalWordsPath,
      );
      final data = jsonDecode(encoded) as List<dynamic>;
      final words = [
        for (final item in data)
          LetterCatchingWord.fromJson(item as Map<String, dynamic>),
      ].where((word) => !word.letterTokens.contains(' ')).toList();
      if (_disposed) return;

      _letterCatchingController = LetterCatchingController(
        words: words,
        distractorLetters: {
          for (final word in words) ...word.letterTokens,
        }.toList(),
      )..addListener(_forwardFeatureNotification);
      if (status == SessionStatus.letterCatching) {
        _letterCatchingController!.start();
      }
    } catch (_) {
      if (_disposed) return;
      _letterCatchingError = FeatureLoadError.letterCatching;
    }
    notifyListeners();
  }

  Future<void> _initializeMemory() async {
    try {
      final encoded = await _assetBundle.loadString(
        _gameContent.localizedAnimalWordsPath,
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
      _memoryError = FeatureLoadError.memoryCards;
    }
    notifyListeners();
  }

  Future<void> _initializeConveyor() async {
    try {
      final encoded = await _assetBundle.loadString(
        _gameContent.localizedAnimalWordsPath,
      );
      final data = jsonDecode(encoded) as List<dynamic>;
      final words = [
        for (final item in data)
          ImageWord.fromJson(item as Map<String, dynamic>),
      ];
      if (_disposed) return;

      _conveyorController = ConveyorController(words: words)
        ..addListener(_forwardFeatureNotification);
      if (status == SessionStatus.conveyor) {
        _conveyorController!.start();
      }
    } catch (_) {
      if (_disposed) return;
      _conveyorError = FeatureLoadError.wordConveyor;
    }
    notifyListeners();
  }

  Future<void> _initializeSpellingQuiz() async {
    try {
      final encoded = await _assetBundle.loadString(
        _gameContent.localizedAnimalWordsPath,
      );
      final data = jsonDecode(encoded) as List<dynamic>;
      final animals = [
        for (final item in data)
          ImageWord.fromJson(item as Map<String, dynamic>),
      ];
      if (_disposed) return;

      _spellingQuizController = SpellingQuizController(
        _audioPlayer,
        animals: animals,
      )..addListener(_forwardFeatureNotification);
      if (status == SessionStatus.spellingQuiz) {
        _spellingQuizController!.start();
        unawaited(_spellingQuizController!.playAudio());
      }
    } catch (_) {
      if (_disposed) return;
      _spellingQuizError = FeatureLoadError.spellingQuiz;
    }
    notifyListeners();
  }

  Future<void> _initializeCrossword() async {
    try {
      final encoded = await _assetBundle.loadString(
        'assets/data/crossword_words.json',
      );
      final data = jsonDecode(encoded) as List<dynamic>;
      final entries = [
        for (final item in data)
          CrosswordEntry.fromJson(item as Map<String, dynamic>),
      ];
      if (_disposed) return;

      _crosswordController = CrosswordController(entries: entries)
        ..addListener(_forwardFeatureNotification);
      if (status == SessionStatus.crossword) {
        _crosswordController!.start();
      }
    } catch (_) {
      if (_disposed) return;
      _crosswordError = FeatureLoadError.crossword;
    }
    notifyListeners();
  }

  Future<void> _initializeLetterPractice() async {
    try {
      final encodedResults = await Future.wait([
        _assetBundle.loadString(_gameContent.localizedAnimalWordsPath),
        _assetBundle.loadString(_gameContent.letterPracticeAlphabetPath),
        _assetBundle.loadString('assets/data/alphabet_objects.json'),
      ]);
      final animalData = jsonDecode(encodedResults[0]) as List<dynamic>;
      final alphabetData = jsonDecode(encodedResults[1]) as List<dynamic>;
      final englishObjectData = jsonDecode(encodedResults[2]) as List<dynamic>;
      final animalWords = [
        for (final item in animalData)
          ImageWord.fromJson(item as Map<String, dynamic>),
      ];
      final alphabet = [
        for (final item in alphabetData)
          AlphabetLetter.fromJson(item as Map<String, dynamic>),
      ];
      final englishObjects = [
        for (final item in englishObjectData)
          AlphabetObject.fromJson(item as Map<String, dynamic>),
      ];
      final alphabetWords = _gameContent.letterPracticeAlphabetWords(
        englishObjects: englishObjects,
        alphabet: alphabet,
      );
      if (_disposed) return;

      _letterPracticeController = LetterPracticeController(
        _audioPlayer,
        alphabetWords: alphabetWords,
        animalWords: animalWords,
        alphabet: alphabet,
      )..addListener(_forwardFeatureNotification);
      if (status == SessionStatus.letterPractice) {
        _letterPracticeController!.start();
        unawaited(_letterPracticeController!.playAudio());
      }
    } catch (_) {
      if (_disposed) return;
      _letterPracticeError = FeatureLoadError.letterPractice;
    }
    notifyListeners();
  }

  Future<void> _initializeLetterLearning() async {
    try {
      final encodedResults = await Future.wait([
        _assetBundle.loadString(_gameContent.letterLearningAlphabetPath),
        _assetBundle.loadString('assets/data/alphabet_objects.json'),
      ]);
      final alphabetData = jsonDecode(encodedResults[0]) as List<dynamic>;
      final objectData = jsonDecode(encodedResults[1]) as List<dynamic>;
      final alphabet = [
        for (final item in alphabetData)
          AlphabetLetter.fromJson(item as Map<String, dynamic>),
      ];
      final englishObjects = [
        for (final item in objectData)
          AlphabetObject.fromJson(item as Map<String, dynamic>),
      ];
      final objects = _gameContent.letterLearningObjects(
        englishObjects: englishObjects,
        alphabet: alphabet,
      );
      if (_disposed) return;

      _letterLearningController = LetterLearningController(
        _audioPlayer,
        alphabet: alphabet,
        objects: objects,
      )..addListener(_forwardFeatureNotification);
      if (status == SessionStatus.letterLearning) {
        _letterLearningController!.start();
        unawaited(_letterLearningController!.playPrompt());
      }
    } catch (_) {
      if (_disposed) return;
      _letterLearningError = FeatureLoadError.letterLearning;
    }
    notifyListeners();
  }

  void _forwardFeatureNotification() {
    final currentStatus = status;
    if (_activityStartedAt != null &&
        _pendingRating == null &&
        _isTerminal(currentStatus)) {
      final activity = _activityFor(currentStatus);
      _pendingRating = _buildCompletion(
        currentStatus,
        _terminalOutcome(currentStatus),
      );
      _ratingActivity = activity;
      status = SessionStatus.rating;
    }
    notifyListeners();
  }

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
    _conveyorController?.removeListener(_forwardFeatureNotification);
    _conveyorController?.dispose();
    _missingLettersController?.removeListener(_forwardFeatureNotification);
    _missingLettersController?.dispose();
    _memoryController?.removeListener(_forwardFeatureNotification);
    _memoryController?.dispose();
    _sentenceQuizController.removeListener(_forwardFeatureNotification);
    _sentenceQuizController.dispose();
    _sentenceComposerController.removeListener(_forwardFeatureNotification);
    _sentenceComposerController.dispose();
    _spellingQuizController?.removeListener(_forwardFeatureNotification);
    _spellingQuizController?.dispose();
    _crosswordController?.removeListener(_forwardFeatureNotification);
    _crosswordController?.dispose();
    _letterLearningController?.removeListener(_forwardFeatureNotification);
    _letterLearningController?.dispose();
    _letterPracticeController?.removeListener(_forwardFeatureNotification);
    _letterPracticeController?.dispose();
    _numberLearningController.removeListener(_forwardFeatureNotification);
    _numberLearningController.dispose();
    _numberComparisonController.removeListener(_forwardFeatureNotification);
    _numberComparisonController.dispose();
    _operationsPracticeController.removeListener(_forwardFeatureNotification);
    _operationsPracticeController.dispose();
    _numberDraggingController.removeListener(_forwardFeatureNotification);
    _numberDraggingController.dispose();
    _numberMemoryController.removeListener(_forwardFeatureNotification);
    _numberMemoryController.dispose();
    _balanceGameController.removeListener(_forwardFeatureNotification);
    _balanceGameController.dispose();
    _logicGameController.removeListener(_forwardFeatureNotification);
    _logicGameController.dispose();
    _shoppingGameController.removeListener(_forwardFeatureNotification);
    _shoppingGameController.dispose();
    _operatorConveyorController.removeListener(_forwardFeatureNotification);
    _operatorConveyorController.dispose();
    _evenOddController.removeListener(_forwardFeatureNotification);
    _evenOddController.dispose();
    super.dispose();
  }
}
