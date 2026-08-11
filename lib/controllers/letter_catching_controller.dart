import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/letter_catching_config.dart';
import '../models/letter_catching_word.dart';
import '../models/letter_catching_world.dart';

const letterCatchingConfig = LetterCatchingConfig(
  fallingSpeed: 150,
  spawnIntervalSeconds: 0.8,
  fallingLetterSize: 42,
  paddleWidth: 90,
  paddleHeight: 20,
  paddleBottomPadding: 18,
  poolSize: 10,
  startingLives: 5,
  winningScore: 10,
  maximumUpdateStep: 1 / 120,
);

enum LetterCatchingState { playing, won, lost }

class LetterCatchingController extends ChangeNotifier {
  final LetterCatchingWorld world;
  bool _isRunning = false;
  LetterCatchingState state = LetterCatchingState.playing;

  LetterCatchingController({
    required List<LetterCatchingWord> words,
    LetterCatchingConfig config = letterCatchingConfig,
    Random? random,
  }) : world = LetterCatchingWorld(
         words: words,
         config: config,
         random: random,
       );

  void start() {
    world.reset();
    _isRunning = true;
    state = LetterCatchingState.playing;
    notifyListeners();
  }

  void stop() => _isRunning = false;

  void resize(double width, double height) => world.resize(width, height);

  void movePaddleBy(double deltaX) {
    if (_isRunning && state == LetterCatchingState.playing) {
      world.movePaddleBy(deltaX);
    }
  }

  void tick(double deltaSeconds) {
    if (!_isRunning) return;
    final previousScore = world.score;
    final previousLives = world.lives;
    final previousWord = world.currentWord;
    final previousMatches = world.matchedLetters.where((value) => value).length;
    world.update(deltaSeconds);

    if (world.score >= world.config.winningScore) {
      state = LetterCatchingState.won;
      _isRunning = false;
    } else if (world.lives <= 0) {
      state = LetterCatchingState.lost;
      _isRunning = false;
    }
    final matches = world.matchedLetters.where((value) => value).length;
    if (world.score != previousScore ||
        world.lives != previousLives ||
        world.currentWord != previousWord ||
        matches != previousMatches ||
        state != LetterCatchingState.playing) {
      notifyListeners();
    }
  }
}
