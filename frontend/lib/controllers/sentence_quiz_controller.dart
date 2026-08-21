import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/layered_person_outfit.dart';
import '../models/sentence_quiz_question.dart';
import '../models/outfit_sentence.dart';
import '../models/sentence_quiz_state.dart';
import '../models/sentence_content.dart';

const sentenceQuizWinningScore = 10;
const sentenceQuizFeedbackDuration = Duration(seconds: 1);

class SentenceQuizController extends ChangeNotifier {
  final Random _random;
  final Duration feedbackDuration;
  final SentenceContent content;

  late SentenceQuizQuestion question;
  SentenceQuizState state = SentenceQuizState.guessing;
  int score = 0;
  int incorrectAttempts = 0;
  int? correctHighlightIndex;
  int? wrongHighlightIndex;
  bool _disposed = false;
  int _sessionGeneration = 0;

  SentenceQuizController({
    Random? random,
    this.feedbackDuration = sentenceQuizFeedbackDuration,
    SentenceContent? content,
  }) : content = content ?? englishSentenceContent,
       _random = random ?? Random() {
    _generateQuestion();
  }

  bool get canSubmit => state == SentenceQuizState.guessing;
  List<String> get optionTexts => [
    for (final option in question.options) content.sentenceFor(option),
  ];

  void start() {
    _sessionGeneration++;
    score = 0;
    incorrectAttempts = 0;
    state = SentenceQuizState.guessing;
    correctHighlightIndex = null;
    wrongHighlightIndex = null;
    _generateQuestion();
    notifyListeners();
  }

  void stop() => _sessionGeneration++;

  Future<void> submit(int guessIndex) async {
    if (!canSubmit) return;
    RangeError.checkValidIndex(guessIndex, question.options, 'guessIndex');

    final generation = _sessionGeneration;
    state = SentenceQuizState.feedback;
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
    if (score >= sentenceQuizWinningScore) {
      state = SentenceQuizState.won;
    } else {
      state = SentenceQuizState.guessing;
      _generateQuestion();
    }
    notifyListeners();
  }

  void _generateQuestion() {
    final outfit = LayeredPersonOutfit.random(_random);
    final person = outfit.person;
    final shirtColor = outfit.shirtColor;
    final jeansColor = outfit.jeansColor;
    final visible = <OutfitSentence>{
      OutfitSentence(
        person: person,
        color: shirtColor,
        piece: ClothingPiece.shirt,
      ),
      OutfitSentence(
        person: person,
        color: jeansColor,
        piece: ClothingPiece.jeans,
      ),
    };
    final visibleOptions = visible.toList();
    final solution = visibleOptions[_random.nextInt(visibleOptions.length)];
    final distractors = <OutfitSentence>[
      for (final candidatePerson in SentencePerson.values)
        for (final candidateColor in GarmentColor.values)
          for (final candidatePiece in ClothingPiece.values)
            OutfitSentence(
              person: candidatePerson,
              color: candidateColor,
              piece: candidatePiece,
            ),
    ]..removeWhere(visible.contains);
    distractors.shuffle(_random);
    final options = [solution, ...distractors.take(3)]..shuffle(_random);

    question = SentenceQuizQuestion(
      outfit: outfit,
      options: options,
      correctIndex: options.indexOf(solution),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
