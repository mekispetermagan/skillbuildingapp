import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../audio/asset_audio_player.dart';
import '../models/operations_practice.dart';

const operationsPracticeConfig = OperationsPracticeConfig();

class OperationsPracticeController extends ChangeNotifier {
  static const _correctPath = 'assets/audio/letter_dragging/correct.mp3';
  static const _wrongPath = 'assets/audio/letter_dragging/pop.wav';

  final AssetAudioPlayer _audioPlayer;
  final Random _random;
  final OperationsPracticeConfig config;
  Set<ElementaryOperator> _operators = Set.of(ElementaryOperator.values);
  OperationsRange _range = OperationsRange.oneToTwelve;
  bool _useColors = true;
  OperationsPracticeState _state = OperationsPracticeState.playing;
  int _score = 0;
  int _incorrectAttempts = 0;
  int _generation = 0;
  bool _disposed = false;
  late ElementaryEquation _equation;

  OperationsPracticeController(
    this._audioPlayer, {
    this.config = operationsPracticeConfig,
    Random? random,
  }) : _random = random ?? Random() {
    _generateEquation();
  }

  Set<ElementaryOperator> get operators => Set.unmodifiable(_operators);
  OperationsRange get range => _range;
  bool get useColors => _useColors;
  OperationsPracticeState get state => _state;
  int get score => _score;
  int get incorrectAttempts => _incorrectAttempts;
  ElementaryEquation get equation => _equation;
  bool get canGuess => _state == OperationsPracticeState.playing;
  int get maximumAnswer => _range == OperationsRange.oneToTwelve ? 12 : 24;
  List<int> get choices => [
    for (var number = 1; number <= maximumAnswer; number++) number,
  ];

  void start() {
    _generation++;
    _score = 0;
    _incorrectAttempts = 0;
    _state = OperationsPracticeState.playing;
    _generateEquation();
    notifyListeners();
  }

  void stop() => _generation++;

  void setOperators(Set<ElementaryOperator> values) {
    if (values.isEmpty || setEquals(values, _operators)) return;
    _generation++;
    _operators = Set.of(values);
    _state = OperationsPracticeState.playing;
    _generateEquation();
    notifyListeners();
  }

  void setRange(OperationsRange value) {
    if (_range == value) return;
    _generation++;
    _range = value;
    _state = OperationsPracticeState.playing;
    _generateEquation();
    notifyListeners();
  }

  void setUseColors(bool value) {
    if (_useColors == value) return;
    _useColors = value;
    notifyListeners();
  }

  Future<void> guess(int number) async {
    if (!canGuess || !choices.contains(number)) return;
    if (number != _equation.answer) {
      _incorrectAttempts++;
      unawaited(_play(_wrongPath));
      return;
    }
    final generation = _generation;
    _score++;
    _state = OperationsPracticeState.correct;
    notifyListeners();
    await _play(_correctPath);
    await Future<void>.delayed(config.successFeedbackDuration);
    if (_disposed || generation != _generation) return;
    if (_score >= config.winningScore) {
      _state = OperationsPracticeState.won;
    } else {
      _state = OperationsPracticeState.playing;
      _generateEquation();
    }
    notifyListeners();
  }

  void _generateEquation() {
    final available = _operators.toList(growable: false);
    final operator = available[_random.nextInt(available.length)];
    _equation = switch (operator) {
      ElementaryOperator.addition => _addition(),
      ElementaryOperator.subtraction => _subtraction(),
      ElementaryOperator.multiplication => _multiplication(),
      ElementaryOperator.division => _division(),
    };
  }

  ElementaryEquation _addition() {
    final answer = _randomBetween(2, maximumAnswer);
    final left = _randomBetween(1, answer - 1);
    return ElementaryEquation(
      left: left,
      operator: ElementaryOperator.addition,
      right: answer - left,
      answer: answer,
    );
  }

  ElementaryEquation _subtraction() {
    final answer = _randomBetween(1, maximumAnswer);
    final right = _randomBetween(1, config.maximumOperand - answer);
    return ElementaryEquation(
      left: answer + right,
      operator: ElementaryOperator.subtraction,
      right: right,
      answer: answer,
    );
  }

  ElementaryEquation _multiplication() {
    final candidates = [
      for (var left = 1; left <= maximumAnswer; left++)
        for (var right = 1; left * right <= maximumAnswer; right++)
          ElementaryEquation(
            left: left,
            operator: ElementaryOperator.multiplication,
            right: right,
            answer: left * right,
          ),
    ];
    final totalWeight = candidates.fold<int>(
      0,
      (sum, equation) => sum + _multiplicationWeight(equation),
    );
    var selection = _random.nextInt(totalWeight);
    for (final equation in candidates) {
      selection -= _multiplicationWeight(equation);
      if (selection < 0) return equation;
    }
    throw StateError('A weighted multiplication candidate must be selected.');
  }

  int _multiplicationWeight(ElementaryEquation equation) =>
      equation.left == 1 || equation.right == 1
      ? config.multiplicationUnitWeight
      : config.multiplicationNonUnitWeight;

  ElementaryEquation _division() {
    final answer = _randomBetween(1, maximumAnswer);
    final maximumDivisor = config.maximumOperand ~/ answer;
    final right = _randomBetween(1, maximumDivisor);
    return ElementaryEquation(
      left: answer * right,
      operator: ElementaryOperator.division,
      right: right,
      answer: answer,
    );
  }

  int _randomBetween(int minimum, int maximum) =>
      minimum + _random.nextInt(maximum - minimum + 1);

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
