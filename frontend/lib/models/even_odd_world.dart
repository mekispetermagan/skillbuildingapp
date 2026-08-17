import 'dart:math';

import 'letter_catching_config.dart';

enum NumberParity {
  even,
  odd;

  bool accepts(int number) => number.isEven == (this == NumberParity.even);
}

class FallingNumber {
  final int id;
  final int number;
  final double x;
  double y;

  FallingNumber({
    required this.id,
    required this.number,
    required this.x,
    required this.y,
  });
}

class EvenOddWorld {
  final LetterCatchingConfig config;
  final Random random;
  final List<FallingNumber> fallingNumbers = [];

  double width = 0;
  double height = 0;
  double paddleX = 0;
  int score = 0;
  late int lives;
  NumberParity parity = NumberParity.even;

  int _nextEntityId = 0;
  double _spawnElapsed = 0;

  EvenOddWorld({required this.config, Random? random})
    : random = random ?? Random() {
    reset();
  }

  double get paddleY =>
      height - config.paddleBottomPadding - config.paddleHeight;

  void resize(double nextWidth, double nextHeight) {
    final wasUninitialized = width == 0;
    width = nextWidth;
    height = nextHeight;
    if (wasUninitialized) paddleX = (width - config.paddleWidth) / 2;
    paddleX = paddleX.clamp(0, max(0, width - config.paddleWidth));
  }

  void reset() {
    fallingNumbers.clear();
    score = 0;
    lives = config.startingLives;
    parity = NumberParity.even;
    _nextEntityId = 0;
    _spawnElapsed = 0;
    paddleX = width > 0 ? (width - config.paddleWidth) / 2 : 0;
  }

  void toggleParity() {
    parity = parity == NumberParity.even ? NumberParity.odd : NumberParity.even;
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
      _spawnNumber();
    }
    for (final falling in fallingNumbers) {
      falling.y += config.fallingSpeed * deltaSeconds;
    }
    _resolvePaddleHits();
    fallingNumbers.removeWhere((falling) => falling.y > height);
  }

  void _spawnNumber() {
    if (width <= config.fallingLetterSize || height <= 0) return;
    fallingNumbers.add(
      FallingNumber(
        id: _nextEntityId++,
        number: random.nextInt(30) + 1,
        x: random.nextDouble() * (width - config.fallingLetterSize),
        y: -config.fallingLetterSize,
      ),
    );
  }

  void _resolvePaddleHits() {
    final paddleRight = paddleX + config.paddleWidth;
    final hitIds = <int>{};
    for (final falling in fallingNumbers) {
      final overlaps =
          falling.x < paddleRight &&
          falling.x + config.fallingLetterSize > paddleX &&
          falling.y < paddleY + config.paddleHeight &&
          falling.y + config.fallingLetterSize > paddleY;
      if (!overlaps) continue;
      hitIds.add(falling.id);
      if (parity.accepts(falling.number)) {
        score++;
        if (score >= config.winningScore) break;
      } else {
        lives = max(0, lives - 1);
        if (lives == 0) break;
      }
    }
    fallingNumbers.removeWhere((falling) => hitIds.contains(falling.id));
  }
}
