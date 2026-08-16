import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/letter_shooting_config.dart';
import '../models/letter_shooting_state.dart';
import '../models/letter_shooting_word.dart';
import '../models/letter_shooting_world.dart';

const letterShootingConfig = LetterShootingConfig(
  projectileSpeed: 600,
  targetSpeed: 50,
  spawnIntervalSeconds: 3,
  projectileSize: 30,
  sourceLetterSize: 38,
  sourceLetterGap: 6,
  sourceLetterColumns: 5,
  targetWidth: 104,
  targetHeight: 50,
  targetLaneGap: 12,
  targetTopPadding: 16,
  cannonWidth: 42,
  cannonHeight: 82,
  cannonBottomClearance: 12,
  maximumUpdateStep: 1 / 120,
  winningScore: 10,
);

class LetterShootingController extends ChangeNotifier {
  final LetterShootingWorld world;
  bool _isRunning = false;
  bool _isAiming = false;
  LetterShootingState state = LetterShootingState.playing;

  LetterShootingController({
    required List<LetterShootingWord> words,
    LetterShootingConfig config = letterShootingConfig,
    Random? random,
  }) : world = LetterShootingWorld(
         words: words,
         config: config,
         random: random,
       );

  void start() {
    world.reset();
    _isRunning = true;
    _isAiming = false;
    state = LetterShootingState.playing;
    notifyListeners();
  }

  void stop() {
    _isRunning = false;
    _isAiming = false;
  }

  void resize(double width, double height) => world.resize(width, height);

  void tick(double deltaSeconds) {
    if (!_isRunning) return;
    final previousScore = world.score;
    world.update(deltaSeconds);
    if (world.score >= world.config.winningScore) {
      _isRunning = false;
      _isAiming = false;
      state = LetterShootingState.ended;
    }
    if (world.score != previousScore || state == LetterShootingState.ended) {
      notifyListeners();
    }
  }

  void tap(GamePoint point) {
    if (!_isRunning || state != LetterShootingState.playing) return;
    for (final source in world.sourceLetters) {
      if (source.bounds.contains(point)) {
        world.loadLetter(source.letter);
        return;
      }
    }
  }

  bool beginAim(GamePoint point) {
    if (!_isRunning || state != LetterShootingState.playing) return false;
    _isAiming = world.aimAt(point);
    return _isAiming;
  }

  void updateAim(GamePoint point) {
    if (_isRunning && _isAiming) world.aimAt(point);
  }

  bool releaseAim() {
    if (!_isRunning || !_isAiming) return false;
    _isAiming = false;
    return world.fire();
  }
}
