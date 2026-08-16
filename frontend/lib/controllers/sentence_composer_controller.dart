import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/layered_person_outfit.dart';
import '../models/outfit_sentence.dart';
import '../models/sentence_composer_state.dart';

const sentenceComposerWinningScore = 10;
const sentenceComposerFeedbackDuration = Duration(seconds: 1);

class SentenceComposerController extends ChangeNotifier {
  final Random _random;
  final Duration feedbackDuration;

  late LayeredPersonOutfit outfit;
  SentencePerson? selectedPerson;
  GarmentColor? selectedColor;
  ClothingPiece? selectedPiece;
  SentenceComposerState state = SentenceComposerState.composing;
  int score = 0;
  int incorrectAttempts = 0;
  bool _disposed = false;
  int _sessionGeneration = 0;

  SentenceComposerController({
    Random? random,
    this.feedbackDuration = sentenceComposerFeedbackDuration,
  }) : _random = random ?? Random() {
    _nextExercise();
  }

  bool get canSelect => state == SentenceComposerState.composing;
  bool get canSubmit =>
      canSelect &&
      selectedPerson != null &&
      selectedColor != null &&
      selectedPiece != null;

  String get composedSentence {
    final name = selectedPerson?.displayName ?? '…';
    final color = selectedColor?.name ?? '…';
    final piece = selectedPiece;
    return switch (piece) {
      ClothingPiece.shirt => '$name wears a $color shirt.',
      ClothingPiece.jeans => '$name wears $color jeans.',
      null => '$name wears $color …',
    };
  }

  void start() {
    _sessionGeneration++;
    score = 0;
    incorrectAttempts = 0;
    state = SentenceComposerState.composing;
    _nextExercise();
    notifyListeners();
  }

  void stop() => _sessionGeneration++;

  void selectPerson(SentencePerson person) {
    if (!canSelect) return;
    selectedPerson = person;
    notifyListeners();
  }

  void selectColor(GarmentColor color) {
    if (!canSelect) return;
    selectedColor = color;
    notifyListeners();
  }

  void selectPiece(ClothingPiece piece) {
    if (!canSelect) return;
    selectedPiece = piece;
    notifyListeners();
  }

  Future<void> submit() async {
    if (!canSubmit) return;
    final generation = _sessionGeneration;
    state = SentenceComposerState.feedback;
    if (_isCorrect) {
      score++;
    } else {
      incorrectAttempts++;
    }
    notifyListeners();

    await Future<void>.delayed(feedbackDuration);
    if (_disposed || generation != _sessionGeneration) return;
    if (score >= sentenceComposerWinningScore) {
      state = SentenceComposerState.won;
    } else {
      state = SentenceComposerState.composing;
      _nextExercise();
    }
    notifyListeners();
  }

  ComposerChoiceAssessment personFeedback(SentencePerson person) {
    if (state != SentenceComposerState.feedback) {
      return ComposerChoiceAssessment.neutral;
    }
    if (person == outfit.person) return ComposerChoiceAssessment.correct;
    if (person == selectedPerson) return ComposerChoiceAssessment.wrong;
    return ComposerChoiceAssessment.neutral;
  }

  ComposerChoiceAssessment colorFeedback(GarmentColor color) {
    final piece = selectedPiece;
    if (state != SentenceComposerState.feedback || piece == null) {
      return ComposerChoiceAssessment.neutral;
    }
    if (color == outfit.colorFor(piece)) {
      return ComposerChoiceAssessment.correct;
    }
    if (color == selectedColor) return ComposerChoiceAssessment.wrong;
    return ComposerChoiceAssessment.neutral;
  }

  ComposerChoiceAssessment pieceFeedback(ClothingPiece piece) =>
      state == SentenceComposerState.feedback && piece == selectedPiece
      ? ComposerChoiceAssessment.correct
      : ComposerChoiceAssessment.neutral;

  bool get _isCorrect {
    final piece = selectedPiece;
    return piece != null &&
        selectedPerson == outfit.person &&
        selectedColor == outfit.colorFor(piece);
  }

  void _nextExercise() {
    outfit = LayeredPersonOutfit.random(_random);
    selectedPerson = null;
    selectedColor = null;
    selectedPiece = null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
