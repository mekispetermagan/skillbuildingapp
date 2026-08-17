import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/conveyor_config.dart';
import '../models/conveyor_state.dart';
import '../models/conveyor_world.dart';
import '../models/image_word.dart';

const conveyorConfig = ConveyorConfig(
  leftBeltWidth: 290,
  rightBeltWidth: 70,
  beltGap: 14,
  outerPadding: 10,
  shelfHeight: 126,
  shelfGap: 16,
  letterSize: 54,
  letterGap: 18,
  leftBeltSpeed: 15,
  rightBeltSpeed: 30,
  startingLives: 5,
  winningScore: 10,
  maximumUpdateStep: 1 / 120,
);

class ConveyorController extends ChangeNotifier {
  final ConveyorWorld world;
  bool _isRunning = false;
  ConveyorState state = ConveyorState.playing;
  int? _selectedLetterId;

  ConveyorController({
    required List<ImageWord> words,
    ConveyorConfig config = conveyorConfig,
    Random? random,
  }) : world = ConveyorWorld(words: words, config: config, random: random);

  void start() {
    world.reset();
    state = ConveyorState.playing;
    _isRunning = true;
    _selectedLetterId = null;
  }

  int? get selectedLetterId => _selectedLetterId;

  void selectLetter(int letterId) {
    if (!_isRunning || !world.letters.any((letter) => letter.id == letterId)) {
      return;
    }
    _selectedLetterId = _selectedLetterId == letterId ? null : letterId;
    notifyListeners();
  }

  void placeSelected(int shelfId) {
    final letterId = _selectedLetterId;
    if (letterId != null) drop(letterId: letterId, shelfId: shelfId);
  }

  void stop() => _isRunning = false;

  void resize(double width, double height) => world.resize(width, height);

  ConveyorState tick(double deltaSeconds) {
    if (!_isRunning) return state;
    final wasPlaying = state == ConveyorState.playing;
    world.update(deltaSeconds);
    if (world.score >= world.config.winningScore) {
      state = ConveyorState.won;
      _isRunning = false;
    } else if (world.lives <= 0) {
      state = ConveyorState.lost;
      _isRunning = false;
    }
    if (wasPlaying && state != ConveyorState.playing) notifyListeners();
    return state;
  }

  bool canAccept({required int letterId, required int shelfId}) =>
      _isRunning &&
      state == ConveyorState.playing &&
      world.canAccept(letterId: letterId, shelfId: shelfId);

  void startDragging(int letterId) {
    if (_isRunning) {
      _selectedLetterId = letterId;
      world.setDragging(letterId, true);
      notifyListeners();
    }
  }

  void cancelDragging(int letterId) => world.setDragging(letterId, false);

  void drop({required int letterId, required int shelfId}) {
    if (!_isRunning || state != ConveyorState.playing) return;
    world.drop(letterId: letterId, shelfId: shelfId);
    _selectedLetterId = null;
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
