import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/layered_person_outfit.dart';
import '../models/sentence_quiz_question.dart';
import '../models/sentence_quiz_sentence.dart';
import '../models/view_data.dart';

const sentenceQuizWinningScore = 10;
const sentenceQuizFeedbackDuration = Duration(seconds: 1);

class SentenceQuizController extends ChangeNotifier {
  final Random _random;
  final Duration feedbackDuration;

  late SentenceQuizQuestion question;
  SentenceQuizState state = SentenceQuizState.guessing;
  int score = 0;
  int? correctHighlightIndex;
  int? wrongHighlightIndex;
  bool _disposed = false;

  SentenceQuizController({
    Random? random,
    this.feedbackDuration = sentenceQuizFeedbackDuration,
  }) : _random = random ?? Random() {
    _generateQuestion();
  }

  bool get canSubmit => state == SentenceQuizState.guessing;

  void start() {
    score = 0;
    state = SentenceQuizState.guessing;
    correctHighlightIndex = null;
    wrongHighlightIndex = null;
    _generateQuestion();
    notifyListeners();
  }

  Future<void> submit(int guessIndex) async {
    if (!canSubmit) return;
    RangeError.checkValidIndex(guessIndex, question.options, 'guessIndex');

    state = SentenceQuizState.feedback;
    correctHighlightIndex = question.correctIndex;
    if (guessIndex == question.correctIndex) {
      score++;
    } else {
      wrongHighlightIndex = guessIndex;
    }
    notifyListeners();

    await Future<void>.delayed(feedbackDuration);
    if (_disposed) return;
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
    final visible = <SentenceQuizSentence>{
      SentenceQuizSentence(
        person: person,
        color: shirtColor,
        piece: ClothingPiece.shirt,
      ),
      SentenceQuizSentence(
        person: person,
        color: jeansColor,
        piece: ClothingPiece.jeans,
      ),
    };
    final visibleOptions = visible.toList();
    final solution = visibleOptions[_random.nextInt(visibleOptions.length)];
    final distractors = <SentenceQuizSentence>[
      for (final candidatePerson in SentencePerson.values)
        for (final candidateColor in GarmentColor.values)
          for (final candidatePiece in ClothingPiece.values)
            SentenceQuizSentence(
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
