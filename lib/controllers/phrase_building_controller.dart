import 'dart:math';

import 'package:flutter/foundation.dart';

import '../audio/asset_audio_player.dart';
import '../models/phrase_building_state.dart';
import '../models/phrase_building_tile.dart';
import '../models/sentence.dart';
import '../utils/string_utils.dart';

class PhraseBuildingController extends ChangeNotifier {
  final List<Sentence> _sentences;
  final AssetAudioPlayer _audioPlayer;
  final Random _random;
  final Duration feedbackDuration;

  final List<PhraseBuildingTile> _sourcePool = [];
  final List<PhraseBuildingTile> _targetPool = [];
  int _sentenceIndex = 0;
  PhraseBuildingState _state = PhraseBuildingState.guessing;
  bool _disposed = false;
  int _sessionGeneration = 0;

  PhraseBuildingController(
    this._audioPlayer, {
    required List<Sentence> sentences,
    Random? random,
    this.feedbackDuration = const Duration(seconds: 1),
  }) : _sentences = List.unmodifiable(sentences),
       _random = random ?? Random() {
    if (_sentences.isEmpty) {
      throw ArgumentError.value(sentences, 'sentences', 'Must not be empty');
    }
    _generateExercise();
  }

  List<PhraseBuildingTile> get sourcePool => List.unmodifiable(_sourcePool);
  List<PhraseBuildingTile> get targetPool => List.unmodifiable(_targetPool);
  PhraseBuildingState get state => _state;
  bool get canMove => _state == PhraseBuildingState.guessing;
  bool get canSubmit => canMove && _targetPool.isNotEmpty;

  void start() {
    _sessionGeneration++;
    _sentenceIndex = 0;
    _state = PhraseBuildingState.guessing;
    _generateExercise();
  }

  void stop() => _sessionGeneration++;

  void move(PhraseBuildingTile tile) {
    if (!canMove) return;

    if (_sourcePool.remove(tile)) {
      _targetPool.add(tile);
      notifyListeners();
      return;
    }
    if (_targetPool.remove(tile)) {
      _sourcePool.add(tile);
      notifyListeners();
    }
  }

  Future<void> submit() async {
    if (!canSubmit) return;

    final generation = _sessionGeneration;
    final expected = toWords(_sentences[_sentenceIndex].text);
    final submitted = _targetPool.map((tile) => tile.word).toList();
    final isCorrect = listEquals(expected, submitted);
    _state = isCorrect
        ? PhraseBuildingState.successFeedback
        : PhraseBuildingState.failureFeedback;
    notifyListeners();

    await Future<void>.delayed(feedbackDuration);
    if (_disposed || generation != _sessionGeneration) return;

    _state = PhraseBuildingState.guessing;
    if (isCorrect) {
      _sentenceIndex = (_sentenceIndex + 1) % _sentences.length;
      _generateExercise();
      await playAudio();
    } else {
      notifyListeners();
    }
  }

  Future<void> playAudio() async {
    try {
      await _audioPlayer.play(_sentences[_sentenceIndex].audioPath);
    } catch (_) {
      // Audio failure must not block the offline activity.
    }
  }

  void _generateExercise() {
    final words = toWords(_sentences[_sentenceIndex].text);
    final tiles = [
      for (final (index, word) in words.indexed)
        PhraseBuildingTile(id: index, word: word),
    ]..shuffle(_random);
    _sourcePool
      ..clear()
      ..addAll(tiles);
    _targetPool.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
