import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../audio/asset_audio_player.dart';
import '../models/image_word.dart';
import '../models/spelling_quiz_question.dart';
import '../models/spelling_quiz_state.dart';

const spellingQuizWinningScore = 10;
const spellingQuizFeedbackDuration = Duration(seconds: 1);

class SpellingQuizController extends ChangeNotifier {
  static const _vowels = 'AEIOU';
  static const _consonants = 'BCDFGHJKLMNPQRSTVWXYZ';

  final List<ImageWord> _animals;
  final AssetAudioPlayer _audioPlayer;
  final Set<String> _animalNames;
  final Random _random;
  final Duration feedbackDuration;

  late SpellingQuizQuestion question;
  SpellingQuizState state = SpellingQuizState.guessing;
  int score = 0;
  int incorrectAttempts = 0;
  int? correctHighlightIndex;
  int? wrongHighlightIndex;
  bool _disposed = false;
  int _sessionGeneration = 0;
  List<ImageWord> _deck = [];
  int _deckIndex = 0;

  SpellingQuizController(
    this._audioPlayer, {
    required List<ImageWord> animals,
    Random? random,
    this.feedbackDuration = spellingQuizFeedbackDuration,
  }) : _animals = List.unmodifiable(animals),
       _animalNames = animals.map((animal) => animal.uppercaseWord).toSet(),
       _random = random ?? Random() {
    if (animals.isEmpty) {
      throw ArgumentError.value(animals, 'animals', 'Must not be empty');
    }
    _resetDeck();
    _generateQuestion();
  }

  bool get canSubmit => state == SpellingQuizState.guessing;

  void start() {
    _sessionGeneration++;
    score = 0;
    incorrectAttempts = 0;
    state = SpellingQuizState.guessing;
    correctHighlightIndex = null;
    wrongHighlightIndex = null;
    _resetDeck();
    _generateQuestion();
    notifyListeners();
  }

  void stop() => _sessionGeneration++;

  Future<void> submit(int guessIndex) async {
    if (!canSubmit) return;
    RangeError.checkValidIndex(guessIndex, question.options, 'guessIndex');

    final generation = _sessionGeneration;
    state = SpellingQuizState.feedback;
    correctHighlightIndex = question.correctIndex;
    if (guessIndex == question.correctIndex) {
      score++;
    } else {
      incorrectAttempts++;
      wrongHighlightIndex = guessIndex;
    }
    notifyListeners();

    await Future<void>.delayed(feedbackDuration);
    if (_disposed || generation != _sessionGeneration) return;
    correctHighlightIndex = null;
    wrongHighlightIndex = null;
    if (score >= spellingQuizWinningScore) {
      state = SpellingQuizState.won;
    } else {
      state = SpellingQuizState.guessing;
      _generateQuestion();
      await playAudio();
    }
    notifyListeners();
  }

  Future<void> playAudio() async {
    try {
      await _audioPlayer.play(question.animal.audioPath);
    } catch (_) {
      // Audio failure must not block the offline activity.
    }
  }

  void _generateQuestion() {
    final animal = _nextAnimal();
    final solution = animal.uppercaseWord;
    final distractors = _distractorsFor(solution)..shuffle(_random);
    if (distractors.length < 3) {
      throw StateError('Not enough spelling variants for $solution.');
    }
    final options = [solution, ...distractors.take(3)]..shuffle(_random);
    question = SpellingQuizQuestion(
      animal: animal,
      options: options,
      correctIndex: options.indexOf(solution),
    );
  }

  List<String> _distractorsFor(String solution) {
    final variants = <String>{};
    for (var index = 1; index < solution.length; index++) {
      final original = solution[index];
      if (solution[index - 1] == ' ' || original == ' ') continue;
      final replacements = _vowels.contains(original) ? _vowels : _consonants;
      for (final replacement in replacements.split('')) {
        if (replacement == original) continue;
        final variant = solution.replaceRange(index, index + 1, replacement);
        if (!_animalNames.contains(variant)) variants.add(variant);
      }
    }
    return variants.toList();
  }

  ImageWord _nextAnimal() {
    if (_deckIndex == _deck.length) _resetDeck();
    return _deck[_deckIndex++];
  }

  void _resetDeck() {
    _deck = [..._animals]..shuffle(_random);
    _deckIndex = 0;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
