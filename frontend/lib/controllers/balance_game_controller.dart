import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../audio/asset_audio_player.dart';
import '../models/balance_game.dart';

const balanceGameConfig = BalanceGameConfig();

class BalanceGameController extends ChangeNotifier {
  static const _correctPath = 'assets/audio/letter_dragging/correct.mp3';
  static const _wrongPath = 'assets/audio/letter_dragging/pop.wav';

  final AssetAudioPlayer _audioPlayer;
  final Random _random;
  final BalanceGameConfig config;
  BalanceGameState _state = BalanceGameState.playing;
  int _score = 0;
  int _incorrectAttempts = 0;
  int _generation = 0;
  int _exerciseId = 0;
  bool _disposed = false;
  ScaleStatus _displayScaleStatus = ScaleStatus.left;
  late List<int> _goodsWeights;
  late List<BalanceStone> _shelfStones;
  final List<BalanceStone> _selectedStones = [];

  BalanceGameController(
    this._audioPlayer, {
    this.config = balanceGameConfig,
    Random? random,
  }) : _random = random ?? Random() {
    _generateExercise();
  }

  BalanceGameState get state => _state;
  int get score => _score;
  int get incorrectAttempts => _incorrectAttempts;
  int get exerciseId => _exerciseId;
  List<int> get goodsWeights => List.unmodifiable(_goodsWeights);
  List<BalanceStone> get shelfStones => List.unmodifiable(_shelfStones);
  List<BalanceStone> get selectedStones => List.unmodifiable(_selectedStones);
  int get leftWeight => _goodsWeights.fold(0, (sum, weight) => sum + weight);
  int get rightWeight =>
      _selectedStones.fold(0, (sum, stone) => sum + stone.weight);
  bool get canSelect => _state == BalanceGameState.playing;
  ScaleStatus get scaleStatus => _displayScaleStatus;
  ScaleStatus get _weightScaleStatus => rightWeight == leftWeight
      ? ScaleStatus.balanced
      : rightWeight > leftWeight
      ? ScaleStatus.right
      : ScaleStatus.left;
  double get leftTrayY => config.leftTrayY[scaleStatus]!;
  double get rightTrayY => config.rightTrayY[scaleStatus]!;
  double get handAngle => config.handAngles[scaleStatus]!;

  void start() {
    _generation++;
    _score = 0;
    _incorrectAttempts = 0;
    _state = BalanceGameState.playing;
    _generateExercise();
    notifyListeners();
  }

  void stop() => _generation++;

  Future<void> selectStone(int stoneId) async {
    if (!canSelect || _selectedStones.length >= config.maximumSelectedStones) {
      return;
    }
    final stone = _shelfStones
        .where((candidate) => candidate.id == stoneId)
        .firstOrNull;
    if (stone == null || _selectedStones.any((item) => item.id == stoneId)) {
      return;
    }

    _selectedStones.add(stone);
    final isCorrect = rightWeight == leftWeight;
    final isFailure =
        rightWeight > leftWeight ||
        _selectedStones.length == config.maximumSelectedStones;
    if (!isCorrect && !isFailure) {
      notifyListeners();
      return;
    }

    final generation = _generation;
    late Future<void> feedbackSound;
    if (isCorrect) {
      _score++;
      _state = BalanceGameState.correct;
      notifyListeners();
      feedbackSound = _play(_correctPath);
    } else {
      _incorrectAttempts++;
      _state = BalanceGameState.incorrect;
      notifyListeners();
      feedbackSound = _play(_wrongPath);
    }
    await Future<void>.delayed(config.outroAnimationDelay);
    if (_disposed || generation != _generation) return;
    _displayScaleStatus = _weightScaleStatus;
    notifyListeners();
    final outroDelay = config.feedbackDuration > config.outroAnimationDuration
        ? config.feedbackDuration
        : config.outroAnimationDuration;
    await Future.wait([feedbackSound, Future<void>.delayed(outroDelay)]);
    if (_disposed || generation != _generation) return;
    if (isCorrect && _score >= config.winningScore) {
      _state = BalanceGameState.won;
    } else {
      _state = BalanceGameState.playing;
      _generateExercise();
    }
    notifyListeners();
  }

  void _generateExercise() {
    _exerciseId++;
    _displayScaleStatus = ScaleStatus.left;
    _goodsWeights = List.generate(
      config.goodsCount,
      (_) => _randomWeight(),
      growable: false,
    );
    final solutions = <List<int>>[];
    for (
      var first = config.minimumWeight;
      first <= config.maximumWeight;
      first++
    ) {
      for (
        var second = config.minimumWeight;
        second <= config.maximumWeight;
        second++
      ) {
        final third = leftWeight - first - second;
        if (third >= config.minimumWeight && third <= config.maximumWeight) {
          solutions.add([first, second, third]);
        }
      }
    }
    final weights = List<int>.of(solutions[_random.nextInt(solutions.length)]);
    while (weights.length < config.shelfStoneCount) {
      weights.add(_randomWeight());
    }
    weights.shuffle(_random);
    _shelfStones = [
      for (final (id, weight) in weights.indexed)
        BalanceStone(id: id, weight: weight),
    ];
    _selectedStones.clear();
  }

  int _randomWeight() =>
      _random.nextInt(config.maximumWeight - config.minimumWeight + 1) +
      config.minimumWeight;

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
