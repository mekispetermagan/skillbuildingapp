import 'dart:async';
import 'dart:math';

import 'package:characters/characters.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../audio/asset_audio_player.dart';
import '../models/letter_dragging_state.dart';
import '../models/letter_dragging_tile.dart';
import '../models/letter_dragging_word.dart';
import 'countdown_controller.dart';

class LetterDraggingController extends ChangeNotifier {
  static const _popPath = 'assets/audio/letter_dragging/pop.wav';
  static const _correctPath = 'assets/audio/letter_dragging/correct.mp3';
  static const _fanfarePath = 'assets/audio/letter_dragging/fanfare.mp3';

  final List<LetterDraggingWord> _words;
  final AssetAudioPlayer _audioPlayer;
  final Random _random;
  final Duration successFeedbackDuration;
  final CountdownController countdown;

  final List<LetterDraggingTile> _tiles = [];
  List<LetterDraggingWord> _deck = [];
  LetterDraggingWord? _currentWord;
  int _deckIndex = 0;
  int _score = 0;
  bool _showImages = true;
  bool _disposed = false;
  int _sessionGeneration = 0;
  LetterDraggingState _state = LetterDraggingState.playing;

  LetterDraggingController(
    this._audioPlayer, {
    required List<LetterDraggingWord> words,
    Random? random,
    CountdownController? countdown,
    this.successFeedbackDuration = const Duration(milliseconds: 500),
  }) : _words = List.unmodifiable(words),
       _random = random ?? Random(),
       countdown =
           countdown ??
           CountdownController(
             totalDuration: const Duration(minutes: 2),
             dangerZone: const Duration(seconds: 15),
           ) {
    if (_words.isEmpty) {
      throw ArgumentError.value(words, 'words', 'Must not be empty');
    }
    this.countdown.addListener(_onCountdownChanged);
  }

  List<LetterDraggingTile> get tiles => List.unmodifiable(_tiles);
  LetterDraggingState get state => _state;
  int get score => _score;
  String? get imagePath => _currentWord?.imagePath;
  bool get showImages => _showImages;
  bool get canReorder => _state == LetterDraggingState.playing;
  bool get canPass => _state == LetterDraggingState.playing;

  void start() {
    _sessionGeneration++;
    _score = 0;
    _showImages = true;
    _state = LetterDraggingState.playing;
    _deck = _words.shuffled(_random);
    _deckIndex = 0;
    _currentWord = null;
    _nextWord();
    countdown.start();
    notifyListeners();
  }

  void setShowImages(bool value) {
    if (_showImages == value) return;
    _showImages = value;
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
      unawaited(_completeWord());
    } else {
      unawaited(_play(_popPath));
      notifyListeners();
    }
  }

  void pass() {
    if (!canPass) return;
    unawaited(_play(_popPath));
    _nextWord();
    notifyListeners();
  }

  void stop() {
    _sessionGeneration++;
    countdown.stop();
  }

  bool get _isSolved {
    final word = _currentWord;
    return word != null &&
        _tiles.map((tile) => tile.letter).join() == word.word;
  }

  Future<void> _completeWord() async {
    final generation = _sessionGeneration;
    _state = LetterDraggingState.successFeedback;
    notifyListeners();
    unawaited(_play(_correctPath));

    await Future<void>.delayed(successFeedbackDuration);
    if (_disposed ||
        generation != _sessionGeneration ||
        _state != LetterDraggingState.successFeedback ||
        countdown.status.isFinished) {
      return;
    }

    _score++;
    _state = LetterDraggingState.playing;
    _nextWord();
    notifyListeners();
  }

  void _nextWord() {
    if (_deckIndex == _deck.length) {
      final previous = _currentWord;
      _deck = _words.shuffled(_random);
      if (_deck.length > 1 && _deck.first == previous) {
        final first = _deck.removeAt(0);
        _deck.add(first);
      }
      _deckIndex = 0;
    }

    final word = _deck[_deckIndex++];
    _currentWord = word;
    final ordered = [
      for (final (index, letter) in word.word.characters.indexed)
        LetterDraggingTile(id: index, letter: letter),
    ];

    var shuffled = ordered.shuffled(_random);
    for (
      var attempt = 0;
      attempt < 20 && _sameOrder(shuffled, ordered);
      attempt++
    ) {
      shuffled = ordered.shuffled(_random);
    }
    if (_sameOrder(shuffled, ordered)) {
      shuffled = [...ordered.skip(1), ordered.first];
    }
    _tiles
      ..clear()
      ..addAll(shuffled);
  }

  bool _sameOrder(
    List<LetterDraggingTile> first,
    List<LetterDraggingTile> second,
  ) => const ListEquality<LetterDraggingTile>().equals(first, second);

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
