import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/even_odd_world.dart';
import '../models/letter_catching_config.dart';
import '../models/letter_catching_state.dart';
import 'letter_catching_controller.dart';

class EvenOddController extends ChangeNotifier {
  final EvenOddWorld world;
  bool _isRunning = false;
  LetterCatchingState state = LetterCatchingState.playing;

  EvenOddController({
    LetterCatchingConfig config = letterCatchingConfig,
    Random? random,
  }) : world = EvenOddWorld(config: config, random: random);

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

  void toggleParity() {
    if (_isRunning && state == LetterCatchingState.playing) {
      world.toggleParity();
      notifyListeners();
    }
  }

  void tick(double deltaSeconds) {
    if (!_isRunning) return;
    final previousScore = world.score;
    final previousLives = world.lives;
    world.update(deltaSeconds);
    if (world.score >= world.config.winningScore) {
      state = LetterCatchingState.won;
      _isRunning = false;
    } else if (world.lives <= 0) {
      state = LetterCatchingState.lost;
      _isRunning = false;
    }
    if (world.score != previousScore ||
        world.lives != previousLives ||
        state != LetterCatchingState.playing) {
      notifyListeners();
    }
  }
}
