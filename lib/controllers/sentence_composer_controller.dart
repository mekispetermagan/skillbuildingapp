import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/layered_person_outfit.dart';
import '../models/sentence_quiz_sentence.dart';
import '../models/view_data.dart';

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
  bool _disposed = false;

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
    score = 0;
    state = SentenceComposerState.composing;
    _nextExercise();
    notifyListeners();
  }

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
    state = SentenceComposerState.feedback;
    if (_isCorrect) score++;
    notifyListeners();

    await Future<void>.delayed(feedbackDuration);
    if (_disposed) return;
    if (score >= sentenceComposerWinningScore) {
      state = SentenceComposerState.won;
    } else {
      state = SentenceComposerState.composing;
      _nextExercise();
    }
    notifyListeners();
  }

  ComposerChoiceFeedback personFeedback(SentencePerson person) {
    if (state != SentenceComposerState.feedback) {
      return ComposerChoiceFeedback.neutral;
    }
    if (person == outfit.person) return ComposerChoiceFeedback.correct;
    if (person == selectedPerson) return ComposerChoiceFeedback.wrong;
    return ComposerChoiceFeedback.neutral;
  }

  ComposerChoiceFeedback colorFeedback(GarmentColor color) {
    final piece = selectedPiece;
    if (state != SentenceComposerState.feedback || piece == null) {
      return ComposerChoiceFeedback.neutral;
    }
    if (color == outfit.colorFor(piece)) {
      return ComposerChoiceFeedback.correct;
    }
    if (color == selectedColor) return ComposerChoiceFeedback.wrong;
    return ComposerChoiceFeedback.neutral;
  }

  ComposerChoiceFeedback pieceFeedback(ClothingPiece piece) =>
      state == SentenceComposerState.feedback && piece == selectedPiece
      ? ComposerChoiceFeedback.correct
      : ComposerChoiceFeedback.neutral;

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
