import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../audio/asset_audio_player.dart';
import '../models/number_comparison.dart';
import 'number_learning_controller.dart';

const numberComparisonConfig = NumberComparisonConfig();

class NumberComparisonController extends ChangeNotifier {
  static const _correctPath = 'assets/audio/letter_dragging/correct.mp3';
  static const _wrongPath = 'assets/audio/letter_dragging/pop.wav';
  static final _scatterGrid = <(double, double)>[
    for (final y in [-5 / 6, -3 / 6, -1 / 6, 1 / 6, 3 / 6, 5 / 6])
      for (final x in [-2 / 3, 0.0, 2 / 3]) (x, y),
  ];

  final AssetAudioPlayer _audioPlayer;
  final Random _random;
  final NumberComparisonConfig config;
  ComparisonRange _range = ComparisonRange.oneToSix;
  NumberArrangement _arrangement = NumberArrangement.pattern;
  NumberComparisonState _state = NumberComparisonState.playing;
  int _score = 0;
  int _incorrectAttempts = 0;
  int _generation = 0;
  bool _disposed = false;
  late int _leftNumber;
  late int _rightNumber;
  late String _leftEmoji;
  late String _rightEmoji;
  late List<(double, double)> _leftPositions;
  late List<(double, double)> _rightPositions;

  NumberComparisonController(
    this._audioPlayer, {
    this.config = numberComparisonConfig,
    Random? random,
  }) : _random = random ?? Random() {
    _generateExercise();
  }

  ComparisonRange get range => _range;
  NumberArrangement get arrangement => _arrangement;
  NumberComparisonState get state => _state;
  int get score => _score;
  int get incorrectAttempts => _incorrectAttempts;
  int get leftNumber => _leftNumber;
  int get rightNumber => _rightNumber;
  String get leftEmoji => _leftEmoji;
  String get rightEmoji => _rightEmoji;
  List<(double, double)> get leftPositions => List.unmodifiable(_leftPositions);
  List<(double, double)> get rightPositions =>
      List.unmodifiable(_rightPositions);
  bool get canGuess => _state == NumberComparisonState.playing;

  void start() {
    _generation++;
    _score = 0;
    _incorrectAttempts = 0;
    _state = NumberComparisonState.playing;
    _generateExercise();
    notifyListeners();
  }

  void stop() => _generation++;

  void setRange(ComparisonRange value) {
    if (_range == value) return;
    _generation++;
    _range = value;
    _state = NumberComparisonState.playing;
    _generateExercise();
    notifyListeners();
  }

  void setArrangement(NumberArrangement value) {
    if (_arrangement == value) return;
    _generation++;
    _arrangement = value;
    _state = NumberComparisonState.playing;
    _generateExercise();
    notifyListeners();
  }

  Future<void> guess(NumberRelation relation) async {
    if (!canGuess) return;
    final correct = _leftNumber < _rightNumber
        ? NumberRelation.lessThan
        : _leftNumber > _rightNumber
        ? NumberRelation.greaterThan
        : NumberRelation.equal;
    if (relation != correct) {
      _incorrectAttempts++;
      unawaited(_play(_wrongPath));
      return;
    }
    final generation = _generation;
    _score++;
    _state = NumberComparisonState.correct;
    notifyListeners();
    await _play(_correctPath);
    await Future<void>.delayed(config.successFeedbackDuration);
    if (_disposed || generation != _generation) return;
    if (_score >= config.winningScore) {
      _state = NumberComparisonState.won;
    } else {
      _state = NumberComparisonState.playing;
      _generateExercise();
    }
    notifyListeners();
  }

  void _generateExercise() {
    final maximum = _range == ComparisonRange.oneToSix ? 6 : 12;
    _leftNumber = _random.nextInt(maximum) + 1;
    _rightNumber = _random.nextInt(maximum) + 1;
    final leftEmojiIndex = _random.nextInt(numberEmojis.length);
    var rightEmojiIndex = _random.nextInt(numberEmojis.length - 1);
    if (rightEmojiIndex >= leftEmojiIndex) rightEmojiIndex++;
    _leftEmoji = numberEmojis[leftEmojiIndex];
    _rightEmoji = numberEmojis[rightEmojiIndex];
    _leftPositions = _positionsFor(_leftNumber);
    _rightPositions = _positionsFor(_rightNumber);
  }

  List<(double, double)> _positionsFor(int count) {
    final positions = List<(double, double)>.of(_scatterGrid)..shuffle(_random);
    return positions.take(count).toList(growable: false);
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
