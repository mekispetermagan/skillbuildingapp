import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../audio/asset_audio_player.dart';
import '../models/logic_game.dart';

const logicGameConfig = LogicGameConfig();

class LogicGameController extends ChangeNotifier {
  static const _correctPath = 'assets/audio/letter_dragging/correct.mp3';
  static const _wrongPath = 'assets/audio/letter_dragging/pop.wav';
  static const _fanfarePath = 'assets/audio/letter_dragging/fanfare.mp3';

  final AssetAudioPlayer _audioPlayer;
  final Random _random;
  final LogicGameConfig config;
  LogicDifficulty _difficulty = LogicDifficulty.easy;
  LogicGameState _state = LogicGameState.playing;
  int _score = 0;
  int _incorrectAttempts = 0;
  int _generation = 0;
  bool _disposed = false;
  late List<LogicObject> _objects;
  late List<LogicProperty> _properties;
  final List<LogicPlacement> _placements = [];

  LogicGameController(
    this._audioPlayer, {
    this.config = logicGameConfig,
    Random? random,
  }) : _random = random ?? Random() {
    _generateExercise();
  }

  LogicDifficulty get difficulty => _difficulty;
  LogicGameState get state => _state;
  int get score => _score;
  int get incorrectAttempts => _incorrectAttempts;
  List<LogicObject> get objects => List.unmodifiable(_objects);
  List<LogicProperty> get properties => List.unmodifiable(_properties);
  List<LogicPlacement> get placements => List.unmodifiable(_placements);
  bool get canPlace => _state == LogicGameState.playing;

  void start() {
    _generation++;
    _score = 0;
    _incorrectAttempts = 0;
    _state = LogicGameState.playing;
    _generateExercise();
    notifyListeners();
  }

  void stop() => _generation++;

  void setDifficulty(LogicDifficulty value) {
    if (_difficulty == value) return;
    _generation++;
    _difficulty = value;
    _state = LogicGameState.playing;
    _generateExercise();
    notifyListeners();
  }

  Future<void> place({
    required int objectId,
    required LogicPoint position,
    required double diagramWidth,
    required double diagramHeight,
  }) async {
    if (!canPlace || _placements.any((item) => item.objectId == objectId)) {
      return;
    }
    final object = _objects.firstWhere((item) => item.id == objectId);
    final geometry = config.geometry(
      difficulty: _difficulty,
      width: diagramWidth,
      height: diagramHeight,
    );
    final actualMembership = [
      for (final circle in geometry.circles)
        _distance(position, circle.center) <= circle.radius,
    ];
    final expectedMembership = [
      for (final property in _properties) property.matches(object),
    ];
    final isCorrect = listEquals(actualMembership, expectedMembership);
    if (!isCorrect) _incorrectAttempts++;
    _placements.add(
      LogicPlacement(
        objectId: objectId,
        position: position,
        isCorrect: isCorrect,
      ),
    );
    final isComplete = _placements.length == config.objectCount;
    final allCorrect =
        isComplete && _placements.every((item) => item.isCorrect);
    if (isComplete) _state = LogicGameState.exerciseFeedback;
    notifyListeners();
    await _play(isCorrect ? _correctPath : _wrongPath);
    if (!isComplete) return;

    final generation = _generation;
    if (allCorrect) {
      _score++;
      await _play(_fanfarePath);
    }
    await Future<void>.delayed(config.exerciseFeedbackDuration);
    if (_disposed || generation != _generation) return;
    if (_score >= config.winningScore) {
      _state = LogicGameState.won;
    } else {
      _state = LogicGameState.playing;
      _generateExercise();
    }
    notifyListeners();
  }

  void _generateExercise() {
    final allObjects = <LogicObject>[
      for (var character = 0; character < 4; character++)
        for (var color = 0; color < 4; color++)
          for (var sunglasses = 0; sunglasses < 2; sunglasses++)
            for (var bicycle = 0; bicycle < 2; bicycle++)
              LogicObject(
                id: character * 16 + color * 4 + sunglasses * 2 + bicycle,
                character: character,
                color: color,
                hasSunglasses: sunglasses == 1,
                hasBicycle: bicycle == 1,
              ),
    ]..shuffle(_random);
    _objects = allObjects.take(config.objectCount).toList(growable: false);

    final kinds = List.of(LogicPropertyKind.values)..shuffle(_random);
    _properties = [
      for (final kind in kinds.take(config.propertyCount(_difficulty)))
        LogicProperty(
          kind: kind,
          value: switch (kind) {
            LogicPropertyKind.character ||
            LogicPropertyKind.color => _random.nextInt(4),
            LogicPropertyKind.sunglasses || LogicPropertyKind.bicycle => 1,
          },
        ),
    ];
    _placements.clear();
  }

  double _distance(LogicPoint first, LogicPoint second) {
    final dx = first.x - second.x;
    final dy = first.y - second.y;
    return sqrt(dx * dx + dy * dy);
  }

  Future<void> _play(String path) async {
    try {
      await _audioPlayer.play(path);
    } catch (_) {
      // Audio failure must not block the offline activity.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
