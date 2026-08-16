import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../audio/asset_audio_player.dart';
import '../models/alphabet_letter.dart';
import '../models/image_word.dart';
import '../models/letter_practice_config.dart';
import '../models/letter_practice_slot.dart';
import '../models/letter_practice_state.dart';

const letterPracticeConfig = LetterPracticeConfig(
  targetCellSize: 48,
  sourceCellSize: 48,
  winningScore: 10,
  completionFeedbackDuration: Duration(seconds: 1),
);

class LetterPracticeController extends ChangeNotifier {
  static const _correctPath = 'assets/audio/letter_dragging/correct.mp3';
  static const _wrongPath = 'assets/audio/letter_dragging/pop.wav';
  static const _fanfarePath = 'assets/audio/letter_dragging/fanfare.mp3';

  final AssetAudioPlayer _audioPlayer;
  final List<ImageWord> _words;
  final List<AlphabetLetter> _alphabet;
  final Random _random;
  final LetterPracticeConfig config;

  late ImageWord currentWord;
  List<LetterPracticeSlot> _slots = [];
  Set<AlphabetDifficulty> _difficulties = {AlphabetDifficulty.beginner};
  bool _useColors = true;
  String? _selectedLetter;
  int _score = 0;
  int _incorrectAttempts = 0;
  LetterPracticeState _state = LetterPracticeState.playing;
  bool _disposed = false;
  int _sessionGeneration = 0;
  ImageWord? _previousWord;

  LetterPracticeController(
    this._audioPlayer, {
    required List<ImageWord> words,
    required List<AlphabetLetter> alphabet,
    this.config = letterPracticeConfig,
    Random? random,
  }) : _words = List.unmodifiable(words),
       _alphabet = List.unmodifiable(alphabet),
       _random = random ?? Random() {
    if (_words.isEmpty || _alphabet.isEmpty) {
      throw ArgumentError('Words and alphabet must not be empty.');
    }
    _generateExercise();
  }

  List<LetterPracticeSlot> get slots => List.unmodifiable(_slots);
  List<AlphabetLetter> get sourceLetters {
    final letters = _alphabet
        .where((item) => _difficulties.contains(item.difficulty))
        .toList();
    letters.sort((first, second) => first.letter.compareTo(second.letter));
    return List.unmodifiable(letters);
  }

  Set<AlphabetDifficulty> get difficulties => Set.unmodifiable(_difficulties);
  bool get useColors => _useColors;
  String? get selectedLetter => _selectedLetter;
  int get score => _score;
  int get incorrectAttempts => _incorrectAttempts;
  LetterPracticeState get state => _state;
  bool get canPlay => _state == LetterPracticeState.playing;
  int get sourceColumnCount => switch (_difficulties.length) {
    1 => 5,
    2 => 6,
    _ => 7,
  };

  void start() {
    _sessionGeneration++;
    _score = 0;
    _incorrectAttempts = 0;
    _state = LetterPracticeState.playing;
    _selectedLetter = null;
    _previousWord = null;
    _generateExercise();
    notifyListeners();
  }

  void stop() => _sessionGeneration++;

  Future<void> playAudio() => _play(currentWord.audioPath);

  void setDifficulties(Set<AlphabetDifficulty> values) {
    if (values.isEmpty ||
        const SetEquality<AlphabetDifficulty>().equals(values, _difficulties)) {
      return;
    }
    _sessionGeneration++;
    _difficulties = Set.of(values);
    _state = LetterPracticeState.playing;
    _selectedLetter = null;
    _generateExercise();
    notifyListeners();
    unawaited(playAudio());
  }

  void setUseColors(bool value) {
    if (_useColors == value) return;
    _useColors = value;
    notifyListeners();
  }

  void selectLetter(String letter) {
    if (!canPlay || !sourceLetters.any((item) => item.letter == letter)) return;
    _selectedLetter = _selectedLetter == letter ? null : letter;
    notifyListeners();
  }

  bool canPlace({required int slotId, required String letter}) {
    if (!canPlay || !sourceLetters.any((item) => item.letter == letter)) {
      return false;
    }
    final slot = _slots.where((item) => item.id == slotId).firstOrNull;
    return slot != null &&
        slot.isTarget &&
        !slot.isFilled &&
        slot.letter == letter;
  }

  Future<void> placeSelected(int slotId) async {
    final letter = _selectedLetter;
    if (letter == null) return;
    await place(slotId: slotId, letter: letter);
  }

  Future<void> place({required int slotId, required String letter}) async {
    if (!canPlay) return;
    if (!canPlace(slotId: slotId, letter: letter)) {
      _incorrectAttempts++;
      unawaited(_play(_wrongPath));
      return;
    }
    final index = _slots.indexWhere(
      (slot) => slot.isTarget && !slot.isFilled && slot.letter == letter,
    );
    _slots[index] = _slots[index].fill();
    _selectedLetter = null;
    final isComplete = _slots
        .where((slot) => slot.isTarget)
        .every((slot) => slot.isFilled);
    if (!isComplete) {
      notifyListeners();
      unawaited(_play(_correctPath));
      return;
    }
    await _completeWord();
  }

  Future<void> _completeWord() async {
    final generation = _sessionGeneration;
    _state = LetterPracticeState.completed;
    notifyListeners();
    await _play(_correctPath);
    await Future<void>.delayed(config.completionFeedbackDuration);
    if (_disposed || generation != _sessionGeneration) return;
    await _play(_fanfarePath);
    if (_disposed || generation != _sessionGeneration) return;
    _score++;
    if (_score >= config.winningScore) {
      _state = LetterPracticeState.won;
    } else {
      _state = LetterPracticeState.playing;
      _generateExercise();
    }
    notifyListeners();
    if (_state == LetterPracticeState.playing) await playAudio();
  }

  void _generateExercise() {
    final activeLetters = sourceLetters.map((item) => item.letter).toSet();
    final eligibleWords = _words
        .where(
          (word) => word.uppercaseWord.split('').any(activeLetters.contains),
        )
        .toList();
    if (eligibleWords.isEmpty) {
      throw StateError('No word contains a selected alphabet letter.');
    }
    var candidates = eligibleWords
        .where((word) => word != _previousWord)
        .toList();
    if (candidates.isEmpty) candidates = eligibleWords;
    currentWord = candidates[_random.nextInt(candidates.length)];
    _previousWord = currentWord;
    final byLetter = {for (final item in _alphabet) item.letter: item};
    _slots = [
      for (final (index, letter) in currentWord.uppercaseWord.split('').indexed)
        LetterPracticeSlot(
          id: index,
          letter: letter,
          colorName: byLetter[letter]?.colorName,
          isTarget: activeLetters.contains(letter),
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
