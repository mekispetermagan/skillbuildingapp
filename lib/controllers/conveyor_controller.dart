import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/conveyor_config.dart';
import '../models/conveyor_word.dart';
import '../models/conveyor_world.dart';
import '../models/view_data.dart';

const conveyorConfig = ConveyorConfig(
  leftBeltWidth: 290,
  rightBeltWidth: 70,
  beltGap: 14,
  outerPadding: 10,
  shelfHeight: 126,
  shelfGap: 16,
  letterSize: 54,
  letterGap: 18,
  leftBeltSpeed: 20,
  rightBeltSpeed: 82,
  startingLives: 5,
  winningScore: 10,
  maximumUpdateStep: 1 / 120,
);

class ConveyorController extends ChangeNotifier {
  final ConveyorWorld world;
  bool _isRunning = false;
  ConveyorState state = ConveyorState.playing;

  ConveyorController({
    required List<ConveyorWord> words,
    ConveyorConfig config = conveyorConfig,
    Random? random,
  }) : world = ConveyorWorld(words: words, config: config, random: random);

  void start() {
    world.reset();
    state = ConveyorState.playing;
    _isRunning = true;
    notifyListeners();
  }

  void stop() => _isRunning = false;

  void resize(double width, double height) => world.resize(width, height);

  void tick(double deltaSeconds) {
    if (!_isRunning) return;
    world.update(deltaSeconds);
    if (world.score >= world.config.winningScore) {
      state = ConveyorState.won;
      _isRunning = false;
    } else if (world.lives <= 0) {
      state = ConveyorState.lost;
      _isRunning = false;
    }
    notifyListeners();
  }

  bool canAccept({required int letterId, required int shelfId}) =>
      _isRunning &&
      state == ConveyorState.playing &&
      world.canAccept(letterId: letterId, shelfId: shelfId);

  void startDragging(int letterId) {
    if (_isRunning) world.setDragging(letterId, true);
  }

  void cancelDragging(int letterId) => world.setDragging(letterId, false);

  void drop({required int letterId, required int shelfId}) {
    if (!_isRunning || state != ConveyorState.playing) return;
    world.drop(letterId: letterId, shelfId: shelfId);
    if (world.score >= world.config.winningScore) {
      state = ConveyorState.won;
      _isRunning = false;
    } else if (world.lives <= 0) {
      state = ConveyorState.lost;
      _isRunning = false;
    }
    notifyListeners();
  }
}
