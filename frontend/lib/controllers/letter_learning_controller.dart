import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../audio/asset_audio_player.dart';
import '../models/alphabet_letter.dart';
import '../models/alphabet_object.dart';
import '../models/letter_learning_config.dart';
import '../models/letter_learning_slot.dart';
import '../models/letter_learning_state.dart';

const letterLearningConfig = LetterLearningConfig(
  targetCellSize: 48,
  sourceCellSize: 48,
  winningScore: 10,
  promptGap: Duration(milliseconds: 200),
  successFeedbackDuration: Duration(seconds: 1),
);

class LetterLearningController extends ChangeNotifier {
  static const _correctPath = 'assets/audio/letter_dragging/correct.mp3';
  static const _wrongPath = 'assets/audio/letter_dragging/pop.wav';

  final AssetAudioPlayer _audioPlayer;
  final List<AlphabetLetter> _alphabet;
  final List<AlphabetObject> _objects;
  final Random _random;
  final LetterLearningConfig config;

  Set<int> _tiers = {1};
  LetterLearningMode _mode = LetterLearningMode.masked;
  LetterLearningState _state = LetterLearningState.playing;
  int _score = 0;
  int _incorrectAttempts = 0;
  int _generation = 0;
  bool _disposed = false;
  AlphabetObject? _previousObject;
  late AlphabetLetter currentLetter;
  late AlphabetObject currentObject;
  List<LetterLearningSlot> _slots = [];
  String? _selectedLetter;

  LetterLearningController(
    this._audioPlayer, {
    required List<AlphabetLetter> alphabet,
    required List<AlphabetObject> objects,
    this.config = letterLearningConfig,
    Random? random,
  }) : _alphabet = List.unmodifiable(alphabet),
       _objects = List.unmodifiable(objects),
       _random = random ?? Random() {
    if (_alphabet.isEmpty || _objects.isEmpty) {
      throw ArgumentError('Alphabet and object catalogs must not be empty.');
    }
    if (!availableTiers.contains(1)) _tiers = {availableTiers.first};
    _generateExercise();
  }

  List<int> get availableTiers =>
      (_alphabet.map((letter) => letter.tier).toSet().toList()..sort());
  Set<int> get tiers => Set.unmodifiable(_tiers);
  LetterLearningMode get mode => _mode;
  LetterLearningState get state => _state;
  int get score => _score;
  int get incorrectAttempts => _incorrectAttempts;
  bool get canGuess => _state == LetterLearningState.playing;
  String? get selectedLetter => _selectedLetter;
  bool get isTargetRevealed =>
      _mode == LetterLearningMode.unmasked ||
      _state != LetterLearningState.playing;
  List<LetterLearningSlot> get slots => List.unmodifiable(_slots);
  List<AlphabetLetter> get sourceLetters {
    final result =
        _alphabet.where((letter) => _tiers.contains(letter.tier)).toList()
          ..sort((a, b) => a.letter.compareTo(b.letter));
    return List.unmodifiable(result);
  }

  int get sourceColumnCount => switch (_tiers.length) {
    1 => 5,
    2 => 6,
    _ => 7,
  };

  void start() {
    _generation++;
    _score = 0;
    _incorrectAttempts = 0;
    _state = LetterLearningState.playing;
    _previousObject = null;
    _selectedLetter = null;
    _generateExercise();
    notifyListeners();
  }

  void stop() => _generation++;

  void setTiers(Set<int> values) {
    if (values.isEmpty || const SetEquality<int>().equals(values, _tiers)) {
      return;
    }
    _generation++;
    _tiers = Set.of(values.where(availableTiers.contains));
    if (_tiers.isEmpty) return;
    _state = LetterLearningState.playing;
    _selectedLetter = null;
    _generateExercise();
    notifyListeners();
    unawaited(playPrompt());
  }

  void setMode(LetterLearningMode value) {
    if (_mode == value) return;
    _mode = value;
    notifyListeners();
  }

  void selectLetter(String letter) {
    if (!canGuess || !sourceLetters.any((item) => item.letter == letter)) {
      return;
    }
    _selectedLetter = _selectedLetter == letter ? null : letter;
    notifyListeners();
  }

  Future<void> guessSelected() async {
    final letter = _selectedLetter;
    if (letter != null) await guess(letter);
  }

  Future<void> guess(String letter) async {
    if (!canGuess || !sourceLetters.any((item) => item.letter == letter)) {
      return;
    }
    if (letter != currentLetter.letter) {
      _incorrectAttempts++;
      unawaited(_play(_wrongPath));
      return;
    }
    final generation = _generation;
    _score++;
    _selectedLetter = null;
    _state = LetterLearningState.correct;
    notifyListeners();
    await _play(_correctPath);
    await Future<void>.delayed(config.successFeedbackDuration);
    if (_disposed || generation != _generation) return;
    if (_score >= config.winningScore) {
      _state = LetterLearningState.won;
      notifyListeners();
      return;
    }
    _state = LetterLearningState.playing;
    _generateExercise();
    notifyListeners();
    await playPrompt();
  }

  Future<void> playPrompt() async {
    final generation = _generation;
    final letterPath = currentLetter.audioPath;
    final wordPath = currentObject.audioPath;
    await _play(letterPath);
    if (letterPath == wordPath) return;
    if (_disposed || generation != _generation) return;
    await Future<void>.delayed(config.promptGap);
    if (_disposed || generation != _generation) return;
    await _play(wordPath);
  }

  void _generateExercise() {
    final active = sourceLetters.map((letter) => letter.letter).toSet();
    final alphabetByLetter = {for (final item in _alphabet) item.letter: item};
    var candidates = _objects
        .where((object) => active.contains(object.letter))
        .where((object) => object.letterTokens.contains(object.letter))
        .toList();
    if (candidates.isEmpty) {
      throw StateError(
        'No object is available for the selected letter groups.',
      );
    }
    final withoutPrevious = candidates
        .where((item) => item != _previousObject)
        .toList();
    if (withoutPrevious.isNotEmpty) candidates = withoutPrevious;
    currentObject = candidates[_random.nextInt(candidates.length)];
    _previousObject = currentObject;
    currentLetter = alphabetByLetter[currentObject.letter]!;
    final tokens = currentObject.letterTokens;
    final targetIndex = tokens.indexOf(currentLetter.letter);
    _slots = [
      for (final (index, letter) in tokens.indexed)
        LetterLearningSlot(
          id: index,
          letter: letter,
          colorName: alphabetByLetter[letter]?.colorName,
          isTarget: index == targetIndex,
          isInSelectedGroups: active.contains(letter),
        ),
    ];
    _selectedLetter = null;
  }

  Future<void> _play(String path) async {
    try {
      await _audioPlayer.play(path);
    } catch (_) {
      // Audio failure must not block the offline activity.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
