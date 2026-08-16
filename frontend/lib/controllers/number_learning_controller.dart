import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../audio/asset_audio_player.dart';
import '../models/number_learning.dart';

const numberEmojis = [
  '🪻',
  '🌸',
  '🍎',
  '🍊',
  '🍇',
  '🐶',
  '🐱',
  '🐰',
  '❤️',
  '⭐',
  '🎁',
  '🌞',
];

const numberLearningConfig = NumberLearningConfig();

class NumberLearningController extends ChangeNotifier {
  static const _correctPath = 'assets/audio/letter_dragging/correct.mp3';
  static const _wrongPath = 'assets/audio/letter_dragging/pop.wav';
  final AssetAudioPlayer _audioPlayer;
  final Random _random;
  final NumberLearningConfig config;
  NumberRange _range = NumberRange.oneToSix;
  bool _useColors = true;
  NumberLearningState _state = NumberLearningState.playing;
  int _score = 0;
  int _incorrectAttempts = 0;
  int _generation = 0;
  bool _disposed = false;
  int? _previousTarget;
  late int _target;
  late String _emoji;

  NumberLearningController(
    this._audioPlayer, {
    this.config = numberLearningConfig,
    Random? random,
  }) : _random = random ?? Random() {
    _generateTarget();
  }

  NumberRange get range => _range;
  bool get useColors => _useColors;
  NumberLearningState get state => _state;
  int get score => _score;
  int get incorrectAttempts => _incorrectAttempts;
  int get target => _target;
  String get emoji => _emoji;
  bool get canGuess => _state == NumberLearningState.playing;
  List<int> get choices => switch (_range) {
    NumberRange.oneToSix => const [1, 2, 3, 4, 5, 6],
    NumberRange.sevenToTwelve => const [7, 8, 9, 10, 11, 12],
  };

  void start() {
    _generation++;
    _score = 0;
    _incorrectAttempts = 0;
    _state = NumberLearningState.playing;
    _previousTarget = null;
    _generateTarget();
    notifyListeners();
  }

  void stop() => _generation++;

  void setRange(NumberRange value) {
    if (_range == value) return;
    _generation++;
    _range = value;
    _state = NumberLearningState.playing;
    _generateTarget();
    notifyListeners();
  }

  void setUseColors(bool value) {
    if (_useColors == value) return;
    _useColors = value;
    notifyListeners();
  }

  Future<void> guess(int number) async {
    if (!canGuess || !choices.contains(number)) return;
    if (number != _target) {
      _incorrectAttempts++;
      unawaited(_play(_wrongPath));
      return;
    }
    final generation = _generation;
    _score++;
    _state = NumberLearningState.correct;
    notifyListeners();
    await _play(_correctPath);
    await Future<void>.delayed(config.successFeedbackDuration);
    if (_disposed || generation != _generation) return;
    if (_score >= config.winningScore) {
      _state = NumberLearningState.won;
    } else {
      _state = NumberLearningState.playing;
      _generateTarget();
    }
    notifyListeners();
  }

  void _generateTarget() {
    var candidates = choices;
    if (_previousTarget != null) {
      candidates = choices
          .where((number) => number != _previousTarget)
          .toList();
    }
    _target = candidates[_random.nextInt(candidates.length)];
    _previousTarget = _target;
    _emoji = numberEmojis[_random.nextInt(numberEmojis.length)];
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
