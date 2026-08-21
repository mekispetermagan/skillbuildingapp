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
import '../models/letter_practice_word_set.dart';

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
  final Map<LetterPracticeWordSet, List<ImageWord>> _wordSets;
  final List<AlphabetLetter> _alphabet;
  final Random _random;
  final LetterPracticeConfig config;

  late ImageWord currentWord;
  List<LetterPracticeSlot> _slots = [];
  Set<int> _tiers = {1};
  bool _useColors = true;
  String? _selectedLetter;
  int _score = 0;
  int _incorrectAttempts = 0;
  LetterPracticeState _state = LetterPracticeState.playing;
  bool _disposed = false;
  int _sessionGeneration = 0;
  ImageWord? _previousWord;
  LetterPracticeWordSet _wordSet = LetterPracticeWordSet.alphabet;

  LetterPracticeController(
    this._audioPlayer, {
    required List<ImageWord> alphabetWords,
    required List<ImageWord> animalWords,
    required List<AlphabetLetter> alphabet,
    this.config = letterPracticeConfig,
    Random? random,
  }) : _wordSets = Map<LetterPracticeWordSet, List<ImageWord>>.unmodifiable({
         LetterPracticeWordSet.alphabet: List<ImageWord>.unmodifiable(
           alphabetWords,
         ),
         LetterPracticeWordSet.animals: List<ImageWord>.unmodifiable(
           animalWords,
         ),
       }),
       _alphabet = List.unmodifiable(alphabet),
       _random = random ?? Random() {
    if (_wordSets.values.any((words) => words.isEmpty) || _alphabet.isEmpty) {
      throw ArgumentError('Word sets and alphabet must not be empty.');
    }
    if (!availableTiers.contains(1)) _tiers = {availableTiers.first};
    _generateExercise();
  }

  List<LetterPracticeSlot> get slots => List.unmodifiable(_slots);
  List<ImageWord> get _words => _wordSets[_wordSet]!;
  List<AlphabetLetter> get sourceLetters {
    final byLetter = {for (final item in _alphabet) item.letter: item};
    final letters = <AlphabetLetter>[
      for (final item in _alphabet)
        if (_tiers.contains(item.tier)) item,
    ];
    final derivedTokens = {
      for (final word in _words)
        for (final token in word.letterTokens)
          if (!byLetter.containsKey(token)) token,
    }.toList()..sort();
    for (final (index, token) in derivedTokens.indexed) {
      final base = _baseLetterFor(token, byLetter);
      if (base != null && _tiers.contains(base.tier)) {
        letters.add(base.withLetter(id: -index - 1, letter: token));
      }
    }
    letters.sort((first, second) => first.letter.compareTo(second.letter));
    return List.unmodifiable(letters);
  }

  List<int> get availableTiers =>
      (_alphabet.map((letter) => letter.tier).toSet().toList()..sort());
  Set<int> get tiers => Set.unmodifiable(_tiers);
  LetterPracticeWordSet get wordSet => _wordSet;
  bool get useColors => _useColors;
  String? get selectedLetter => _selectedLetter;
  int get score => _score;
  int get incorrectAttempts => _incorrectAttempts;
  LetterPracticeState get state => _state;
  bool get canPlay => _state == LetterPracticeState.playing;
  int get sourceColumnCount => switch (_tiers.length) {
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

  void setWordSet(LetterPracticeWordSet value) {
    if (value == _wordSet) return;
    _sessionGeneration++;
    _wordSet = value;
    _state = LetterPracticeState.playing;
    _selectedLetter = null;
    _previousWord = null;
    _generateExercise();
    notifyListeners();
    unawaited(playAudio());
  }

  void setTiers(Set<int> values) {
    if (values.isEmpty || const SetEquality<int>().equals(values, _tiers)) {
      return;
    }
    _sessionGeneration++;
    _tiers = Set.of(values.where(availableTiers.contains));
    if (_tiers.isEmpty) return;
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
        .where((word) => word.letterTokens.any(activeLetters.contains))
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
      for (final (index, letter) in currentWord.letterTokens.indexed)
        LetterPracticeSlot(
          id: index,
          letter: letter,
          colorName: byLetter[letter]?.colorName,
          isTarget: activeLetters.contains(letter),
        ),
    ];
    _selectedLetter = null;
  }

  AlphabetLetter? _baseLetterFor(
    String token,
    Map<String, AlphabetLetter> byLetter,
  ) {
    if (token.length < 2) return null;
    return byLetter[token.substring(1)];
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
