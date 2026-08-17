import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../audio/asset_audio_player.dart';
import '../models/letter_dragging_state.dart';
import '../models/number_dragging.dart';
import 'countdown_controller.dart';

const numberDraggingConfig = NumberDraggingConfig();

class NumberDraggingController extends ChangeNotifier {
  static const _popPath = 'assets/audio/letter_dragging/pop.wav';
  static const _correctPath = 'assets/audio/letter_dragging/correct.mp3';
  static const _fanfarePath = 'assets/audio/letter_dragging/fanfare.mp3';

  final AssetAudioPlayer _audioPlayer;
  final Random _random;
  final NumberDraggingConfig config;
  final CountdownController countdown;
  final List<NumberDraggingTile> _tiles = [];
  NumberDraggingRange _range = NumberDraggingRange.oneToTwelve;
  LetterDraggingState _state = LetterDraggingState.playing;
  int _score = 0;
  int _passedItems = 0;
  int _exerciseId = 0;
  int _sessionGeneration = 0;
  bool _disposed = false;

  NumberDraggingController(
    this._audioPlayer, {
    this.config = numberDraggingConfig,
    Random? random,
    CountdownController? countdown,
  }) : _random = random ?? Random(),
       countdown =
           countdown ??
           CountdownController(
             totalDuration: config.totalDuration,
             dangerZone: config.dangerZone,
           ) {
    this.countdown.addListener(_onCountdownChanged);
    _generateExercise();
  }

  List<NumberDraggingTile> get tiles => List.unmodifiable(_tiles);
  NumberDraggingRange get range => _range;
  LetterDraggingState get state => _state;
  int get score => _score;
  int get passedItems => _passedItems;
  bool get canReorder => _state == LetterDraggingState.playing;
  bool get canPass => _state == LetterDraggingState.playing;
  int get maximumNumber => switch (_range) {
    NumberDraggingRange.oneToTwelve => 12,
    NumberDraggingRange.oneToTwentyFour => 24,
    NumberDraggingRange.oneToSixty => 60,
  };

  void start() {
    _sessionGeneration++;
    _score = 0;
    _passedItems = 0;
    _state = LetterDraggingState.playing;
    _generateExercise();
    countdown.start();
    notifyListeners();
  }

  void setRange(NumberDraggingRange value) {
    if (_range == value) return;
    _sessionGeneration++;
    _range = value;
    _state = LetterDraggingState.playing;
    _generateExercise();
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    if (!canReorder ||
        oldIndex < 0 ||
        oldIndex >= _tiles.length ||
        newIndex < 0 ||
        newIndex >= _tiles.length) {
      return;
    }
    final tile = _tiles.removeAt(oldIndex);
    _tiles.insert(newIndex, tile);
    if (_isSolved) {
      unawaited(_completeExercise());
    } else {
      unawaited(_play(_popPath));
      notifyListeners();
    }
  }

  void pass() {
    if (!canPass) return;
    _passedItems++;
    unawaited(_play(_popPath));
    _generateExercise();
    notifyListeners();
  }

  void stop() {
    _sessionGeneration++;
    countdown.stop();
  }

  bool get _isSolved {
    for (var index = 1; index < _tiles.length; index++) {
      if (_tiles[index - 1].number > _tiles[index].number) return false;
    }
    return true;
  }

  Future<void> _completeExercise() async {
    final generation = _sessionGeneration;
    _state = LetterDraggingState.successFeedback;
    notifyListeners();
    unawaited(_play(_correctPath));
    await Future<void>.delayed(config.successFeedbackDuration);
    if (_disposed ||
        generation != _sessionGeneration ||
        _state != LetterDraggingState.successFeedback ||
        countdown.status.isFinished) {
      return;
    }
    _score++;
    _state = LetterDraggingState.playing;
    _generateExercise();
    notifyListeners();
  }

  void _generateExercise() {
    List<int> numbers;
    do {
      numbers = [
        for (var index = 0; index < config.itemCount; index++)
          _random.nextInt(maximumNumber) + 1,
      ];
    } while (_isNonDecreasing(numbers));
    final exerciseId = _exerciseId++;
    _tiles
      ..clear()
      ..addAll([
        for (final (index, number) in numbers.indexed)
          NumberDraggingTile(
            id: exerciseId * config.itemCount + index,
            number: number,
          ),
      ]);
  }

  bool _isNonDecreasing(List<int> numbers) {
    for (var index = 1; index < numbers.length; index++) {
      if (numbers[index - 1] > numbers[index]) return false;
    }
    return true;
  }

  void _onCountdownChanged() {
    if (!countdown.status.isFinished || _state == LetterDraggingState.result) {
      return;
    }
    _state = LetterDraggingState.result;
    unawaited(_play(_fanfarePath));
    notifyListeners();
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
    countdown.removeListener(_onCountdownChanged);
    countdown.dispose();
    super.dispose();
  }
}
