import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/conveyor_config.dart';
import '../models/conveyor_state.dart';
import '../models/operator_conveyor_world.dart';
import 'conveyor_controller.dart';

class OperatorConveyorController extends ChangeNotifier {
  final OperatorConveyorWorld world;
  bool _isRunning = false;
  ConveyorState state = ConveyorState.playing;
  int? _selectedOperatorId;

  OperatorConveyorController({
    ConveyorConfig config = conveyorConfig,
    Random? random,
  }) : world = OperatorConveyorWorld(config: config, random: random);

  int? get selectedOperatorId => _selectedOperatorId;

  void start() {
    world.reset();
    state = ConveyorState.playing;
    _isRunning = true;
    _selectedOperatorId = null;
  }

  void stop() => _isRunning = false;
  void resize(double width, double height) => world.resize(width, height);

  ConveyorState tick(double deltaSeconds) {
    if (!_isRunning) return state;
    final wasPlaying = state == ConveyorState.playing;
    world.update(deltaSeconds);
    _updateEndState();
    if (wasPlaying && state != ConveyorState.playing) notifyListeners();
    return state;
  }

  void selectOperator(int operatorId) {
    if (!_isRunning || !world.operators.any((tile) => tile.id == operatorId)) {
      return;
    }
    _selectedOperatorId = _selectedOperatorId == operatorId ? null : operatorId;
    notifyListeners();
  }

  void placeSelected(int shelfId) {
    final operatorId = _selectedOperatorId;
    if (operatorId != null) drop(operatorId: operatorId, shelfId: shelfId);
  }

  bool canAccept({required int operatorId, required int shelfId}) =>
      _isRunning &&
      state == ConveyorState.playing &&
      world.canAccept(operatorId: operatorId, shelfId: shelfId);

  void startDragging(int operatorId) {
    if (!_isRunning) return;
    _selectedOperatorId = operatorId;
    world.setDragging(operatorId, true);
    notifyListeners();
  }

  void cancelDragging(int operatorId) => world.setDragging(operatorId, false);

  void drop({required int operatorId, required int shelfId}) {
    if (!_isRunning || state != ConveyorState.playing) return;
    world.drop(operatorId: operatorId, shelfId: shelfId);
    _selectedOperatorId = null;
    _updateEndState();
    notifyListeners();
  }

  void _updateEndState() {
    if (world.score >= world.config.winningScore) {
      state = ConveyorState.won;
      _isRunning = false;
    } else if (world.lives <= 0) {
      state = ConveyorState.lost;
      _isRunning = false;
    }
  }
}
