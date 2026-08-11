import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../audio/asset_audio_player.dart';
import '../models/phrase_building_state.dart';
import '../models/phrase_building_tile.dart';
import '../models/sentence.dart';
import '../models/letter_dragging_state.dart';
import '../models/letter_dragging_tile.dart';
import '../models/letter_dragging_word.dart';
import '../models/letter_catching_word.dart';
import '../models/conveyor_word.dart';
import '../models/letter_shooting_word.dart';
import '../models/missing_letter_slot.dart';
import '../models/missing_letter_tile.dart';
import '../models/missing_letters_state.dart';
import '../models/missing_letters_word.dart';
import '../models/memory_card_data.dart';
import '../models/memory_pair.dart';
import 'countdown_controller.dart';
import 'letter_dragging_controller.dart';
import 'letter_catching_controller.dart';
import 'conveyor_controller.dart';
import 'letter_shooting_controller.dart';
import 'memory_controller.dart';
import 'missing_letters_controller.dart';
import 'phrase_building_controller.dart';

enum SessionStatus {
  menu,
  phraseBuilding,
  letterDragging,
  missingLetters,
  letterShooting,
  memory,
  letterCatching,
  conveyor,
  feature8,
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
  SessionStatus status = SessionStatus.menu;

  SessionController({AssetBundle? assetBundle, AssetAudioPlayer? audioPlayer})
    : _assetBundle = assetBundle ?? rootBundle,
      _audioPlayer = audioPlayer ?? SoloudAssetAudioPlayer() {
    unawaited(_initializePhraseBuilding());
    unawaited(_initializeLetterDragging());
    unawaited(_initializeLetterShooting());
    unawaited(_initializeLetterCatching());
    unawaited(_initializeConveyor());
    unawaited(_initializeMissingLetters());
    unawaited(_initializeMemory());
  }

  late final List<(String, VoidCallback)> menuItems = [
    ('Phrase building', () => _open(SessionStatus.phraseBuilding)),
    ('Letter dragging', openLetterDragging),
    ('Missing letters', openMissingLetters),
    ('Letter shooting', openLetterShooting),
    ('Memory cards', () => _open(SessionStatus.memory)),
    ('Letter catching', openLetterCatching),
    ('Word conveyor', openConveyor),
    ('Feature 8', () => _open(SessionStatus.feature8)),
  ];

  bool get phraseBuildingIsLoading =>
      _phraseBuildingController == null && _phraseBuildingError == null;
  String? get phraseBuildingError => _phraseBuildingError;
  List<PhraseBuildingTile> get phraseBuildingSourcePool =>
      _phraseBuildingController?.sourcePool ?? const [];
  List<PhraseBuildingTile> get phraseBuildingTargetPool =>
      _phraseBuildingController?.targetPool ?? const [];
  PhraseBuildingState get phraseBuildingState =>
      _phraseBuildingController?.state ?? PhraseBuildingState.guessing;

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

  bool get letterDraggingIsLoading =>
      _letterDraggingController == null && _letterDraggingError == null;
  String? get letterDraggingError => _letterDraggingError;
  List<LetterDraggingTile> get letterDraggingTiles =>
      _letterDraggingController?.tiles ?? const [];
  LetterDraggingState get letterDraggingState =>
      _letterDraggingController?.state ?? LetterDraggingState.playing;
  int get letterDraggingScore => _letterDraggingController?.score ?? 0;
  CountdownController? get letterDraggingCountdown =>
      _letterDraggingController?.countdown;

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

  bool get letterShootingIsLoading =>
      _letterShootingController == null && _letterShootingError == null;
  String? get letterShootingError => _letterShootingError;
  LetterShootingController? get letterShootingController =>
      _letterShootingController;

  void openLetterShooting() {
    _letterShootingController?.start();
    _open(SessionStatus.letterShooting);
  }

  void restartLetterShooting() => _letterShootingController?.start();

  bool get letterCatchingIsLoading =>
      _letterCatchingController == null && _letterCatchingError == null;
  String? get letterCatchingError => _letterCatchingError;
  LetterCatchingController? get letterCatchingController =>
      _letterCatchingController;

  void openLetterCatching() {
    _letterCatchingController?.start();
    _open(SessionStatus.letterCatching);
  }

  void restartLetterCatching() => _letterCatchingController?.start();

  bool get conveyorIsLoading =>
      _conveyorController == null && _conveyorError == null;
  String? get conveyorError => _conveyorError;
  ConveyorController? get conveyorController => _conveyorController;

  void openConveyor() {
    _conveyorController?.start();
    _open(SessionStatus.conveyor);
  }

  void restartConveyor() => _conveyorController?.start();

  bool get missingLettersIsLoading =>
      _missingLettersController == null && _missingLettersError == null;
  String? get missingLettersError => _missingLettersError;
  List<MissingLetterSlot> get missingLetterSlots =>
      _missingLettersController?.slots ?? const [];
  List<MissingLetterTile> get missingLetterPool =>
      _missingLettersController?.pool ?? const [];
  MissingLettersState get missingLettersState =>
      _missingLettersController?.state ?? MissingLettersState.solving;
  int get missingLettersScore => _missingLettersController?.score ?? 0;
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

  bool get memoryIsLoading => _memoryController == null && _memoryError == null;
  String? get memoryError => _memoryError;
  List<MemoryCardData> get memoryCards => _memoryController?.cards ?? const [];
  bool get memoryIsComplete => _memoryController?.isComplete ?? false;
  Future<void> memorySelect(int cardId) =>
      _memoryController?.select(cardId) ?? Future.value();
  void memoryStartNewGame() => _memoryController?.startNewGame();

  void openMenu() {
    unawaited(_audioPlayer.stop());
    _letterDraggingController?.stop();
    _letterShootingController?.stop();
    _letterCatchingController?.stop();
    _conveyorController?.stop();
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
        'assets/data/letter_dragging_words.json',
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
        'assets/data/letter_dragging_words.json',
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

      _letterShootingController = LetterShootingController(words: words);
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

      _letterCatchingController = LetterCatchingController(words: words);
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
        'assets/data/memory_pairs.json',
      );
      final data = jsonDecode(encoded) as List<dynamic>;
      final pairs = [
        for (final item in data)
          MemoryPair.fromJson(item as Map<String, dynamic>),
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
        'assets/data/memory_pairs.json',
      );
      final data = jsonDecode(encoded) as List<dynamic>;
      final words = [
        for (final item in data)
          ConveyorWord.fromJson(item as Map<String, dynamic>),
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
    _letterShootingController?.dispose();
    _letterCatchingController?.dispose();
    _conveyorController?.dispose();
    _missingLettersController?.removeListener(_forwardFeatureNotification);
    _missingLettersController?.dispose();
    _memoryController?.removeListener(_forwardFeatureNotification);
    _memoryController?.dispose();
    super.dispose();
  }
}
