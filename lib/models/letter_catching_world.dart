import 'dart:math';

import 'letter_catching_config.dart';
import 'letter_catching_word.dart';

class FallingLetter {
  final int id;
  final String letter;
  final double x;
  double y;

  FallingLetter({
    required this.id,
    required this.letter,
    required this.x,
    required this.y,
  });
}

class LetterCatchingWorld {
  static const alphabet = <String>[
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];

  final List<LetterCatchingWord> words;
  final LetterCatchingConfig config;
  final Random random;
  final List<FallingLetter> fallingLetters = [];

  double width = 0;
  double height = 0;
  double paddleX = 0;
  int score = 0;
  late int lives;
  late LetterCatchingWord currentWord;
  List<bool> matchedLetters = const [];
  List<String> sourcePool = const [];

  List<LetterCatchingWord> _deck = [];
  int _deckIndex = 0;
  int _nextEntityId = 0;
  double _spawnElapsed = 0;

  LetterCatchingWorld({
    required List<LetterCatchingWord> words,
    required this.config,
    Random? random,
  }) : words = List.unmodifiable(words),
       random = random ?? Random() {
    if (words.isEmpty) {
      throw ArgumentError.value(words, 'words', 'Must not be empty');
    }
    if (words.any((word) => word.word.length > config.poolSize)) {
      throw ArgumentError('Pool must fit every target word.');
    }
    reset();
  }

  double get paddleY =>
      height - config.paddleBottomPadding - config.paddleHeight;
  bool get isWordComplete => matchedLetters.every((matched) => matched);

  void resize(double nextWidth, double nextHeight) {
    final wasUninitialized = width == 0;
    width = nextWidth;
    height = nextHeight;
    if (wasUninitialized) paddleX = (width - config.paddleWidth) / 2;
    paddleX = paddleX.clamp(0, max(0, width - config.paddleWidth));
  }

  void reset() {
    fallingLetters.clear();
    score = 0;
    lives = config.startingLives;
    _deck = [...words]..shuffle(random);
    _deckIndex = 0;
    _nextEntityId = 0;
    _spawnElapsed = 0;
    paddleX = width > 0 ? (width - config.paddleWidth) / 2 : 0;
    _nextWord();
  }

  void movePaddleBy(double deltaX) {
    paddleX = (paddleX + deltaX).clamp(0, max(0, width - config.paddleWidth));
  }

  void update(double deltaSeconds) {
    var remaining = deltaSeconds.clamp(0, 0.25).toDouble();
    while (remaining > 0) {
      final step = min(remaining, config.maximumUpdateStep);
      _updateStep(step);
      remaining -= step;
      if (score >= config.winningScore || lives <= 0) break;
    }
  }

  void _updateStep(double deltaSeconds) {
    _spawnElapsed += deltaSeconds;
    while (_spawnElapsed >= config.spawnIntervalSeconds) {
      _spawnElapsed -= config.spawnIntervalSeconds;
      _spawnLetter();
    }
    for (final falling in fallingLetters) {
      falling.y += config.fallingSpeed * deltaSeconds;
    }
    _resolvePaddleHits();
    fallingLetters.removeWhere((falling) => falling.y > height);
  }

  void _spawnLetter() {
    if (width <= config.fallingLetterSize || height <= 0) return;
    fallingLetters.add(
      FallingLetter(
        id: _nextEntityId++,
        letter: sourcePool[random.nextInt(sourcePool.length)],
        x: random.nextDouble() * (width - config.fallingLetterSize),
        y: -config.fallingLetterSize,
      ),
    );
  }

  void _resolvePaddleHits() {
    final paddleLeft = paddleX;
    final paddleRight = paddleX + config.paddleWidth;
    final paddleTop = paddleY;
    final hitIds = <int>{};
    for (final falling in fallingLetters) {
      final fallingRight = falling.x + config.fallingLetterSize;
      final fallingBottom = falling.y + config.fallingLetterSize;
      final overlaps =
          falling.x < paddleRight &&
          fallingRight > paddleLeft &&
          falling.y < paddleY + config.paddleHeight &&
          fallingBottom > paddleTop;
      if (!overlaps) continue;

      hitIds.add(falling.id);
      final matchIndex = _firstUnmatchedIndex(falling.letter);
      if (matchIndex == -1) {
        lives = max(0, lives - 1);
        if (lives == 0) break;
        continue;
      }
      matchedLetters[matchIndex] = true;
      if (isWordComplete) {
        score++;
        fallingLetters.clear();
        if (score < config.winningScore) _nextWord();
        return;
      }
    }
    fallingLetters.removeWhere((falling) => hitIds.contains(falling.id));
  }

  int _firstUnmatchedIndex(String letter) {
    for (var index = 0; index < currentWord.word.length; index++) {
      if (!matchedLetters[index] && currentWord.word[index] == letter) {
        return index;
      }
    }
    return -1;
  }

  void _nextWord() {
    if (_deckIndex == _deck.length) {
      final previous = currentWord;
      _deck = [...words]..shuffle(random);
      if (_deck.length > 1 && _deck.first == previous) {
        final first = _deck.removeAt(0);
        _deck.add(first);
      }
      _deckIndex = 0;
    }
    currentWord = _deck[_deckIndex++];
    matchedLetters = List.filled(currentWord.word.length, false);
    final distractors =
        alphabet.where((letter) => !currentWord.word.contains(letter)).toList()
          ..shuffle(random);
    sourcePool = [
      ...currentWord.word.split(''),
      ...distractors.take(config.poolSize - currentWord.word.length),
    ]..shuffle(random);
  }
}
