import 'dart:math';

import 'letter_shooting_config.dart';
import 'letter_shooting_word.dart';

class GamePoint {
  final double x;
  final double y;

  const GamePoint(this.x, this.y);

  GamePoint operator +(GamePoint other) => GamePoint(x + other.x, y + other.y);
  GamePoint operator *(double factor) => GamePoint(x * factor, y * factor);
}

class GameRect {
  final double left;
  final double top;
  final double width;
  final double height;

  const GameRect(this.left, this.top, this.width, this.height);

  double get right => left + width;
  double get bottom => top + height;

  bool contains(GamePoint point) =>
      point.x >= left &&
      point.x <= right &&
      point.y >= top &&
      point.y <= bottom;

  bool overlaps(GameRect other) =>
      left < other.right &&
      right > other.left &&
      top < other.bottom &&
      bottom > other.top;
}

class LetterTarget {
  final int entityId;
  final LetterShootingWord word;
  final int missingIndex;
  double x;
  final double y;
  final int direction;
  bool isSolved;

  LetterTarget({
    required this.entityId,
    required this.word,
    required this.missingIndex,
    required this.x,
    required this.y,
    required this.direction,
    this.isSolved = false,
  });

  String get missingLetter => word.word[missingIndex];
  String get displayWord => isSolved
      ? word.word
      : word.word.replaceRange(missingIndex, missingIndex + 1, '_');
}

class LetterProjectile {
  final int entityId;
  final String letter;
  double x;
  double y;
  final double velocityX;
  final double velocityY;

  LetterProjectile({
    required this.entityId,
    required this.letter,
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
  });
}

class SourceLetter {
  final String letter;
  final GameRect bounds;

  const SourceLetter({required this.letter, required this.bounds});
}

class LetterShootingWorld {
  static const letters = <String>['A', 'E', 'I', 'O', 'U'];

  final List<LetterShootingWord> words;
  final LetterShootingConfig config;
  final Random random;
  final List<LetterTarget> targets = [];
  final List<LetterProjectile> projectiles = [];

  double width = 0;
  double height = 0;
  double elapsedSeconds = 0;
  double cannonAngle = 0;
  String? loadedLetter;
  int score = 0;
  int _nextEntityId = 0;
  double _spawnElapsed = 0;

  LetterShootingWorld({
    required List<LetterShootingWord> words,
    required this.config,
    Random? random,
  }) : words = List.unmodifiable(words),
       random = random ?? Random() {
    if (words.isEmpty) {
      throw ArgumentError.value(words, 'words', 'Must not be empty');
    }
  }

  double get sourceAreaHeight {
    final rows = (letters.length / config.sourceLetterColumns).ceil();
    return rows * config.sourceLetterSize + (rows - 1) * config.sourceLetterGap;
  }

  GamePoint get cannonPivot => GamePoint(
    width / 2,
    height - sourceAreaHeight - config.cannonBottomClearance,
  );

  List<SourceLetter> get sourceLetters {
    final columns = min(config.sourceLetterColumns, letters.length);
    final boardWidth =
        columns * config.sourceLetterSize +
        (columns - 1) * config.sourceLetterGap;
    final startX = (width - boardWidth) / 2;
    final startY = height - sourceAreaHeight;
    return [
      for (final (index, letter) in letters.indexed)
        SourceLetter(
          letter: letter,
          bounds: GameRect(
            startX +
                (index % config.sourceLetterColumns) *
                    (config.sourceLetterSize + config.sourceLetterGap),
            startY +
                (index ~/ config.sourceLetterColumns) *
                    (config.sourceLetterSize + config.sourceLetterGap),
            config.sourceLetterSize,
            config.sourceLetterSize,
          ),
        ),
    ];
  }

  void resize(double nextWidth, double nextHeight) {
    width = nextWidth;
    height = nextHeight;
  }

  void reset() {
    targets.clear();
    projectiles.clear();
    loadedLetter = null;
    cannonAngle = 0;
    score = 0;
    elapsedSeconds = 0;
    _spawnElapsed = 0;
    _nextEntityId = 0;
  }

  void loadLetter(String letter) {
    if (letters.contains(letter)) loadedLetter = letter;
  }

  bool aimAt(GamePoint point) {
    final pivot = cannonPivot;
    if (point.y >= pivot.y) return false;
    final dx = point.x - pivot.x;
    final dy = point.y - pivot.y;
    cannonAngle = atan2(dy, dx) + pi / 2;
    return true;
  }

  bool fire() {
    final letter = loadedLetter;
    if (letter == null) return false;
    final direction = GamePoint(sin(cannonAngle), -cos(cannonAngle));
    final muzzle = cannonPivot + direction * config.cannonHeight;
    projectiles.add(
      LetterProjectile(
        entityId: _nextEntityId++,
        letter: letter,
        x: muzzle.x,
        y: muzzle.y,
        velocityX: direction.x * config.projectileSpeed,
        velocityY: direction.y * config.projectileSpeed,
      ),
    );
    loadedLetter = null;
    return true;
  }

  void update(double deltaSeconds) {
    var remaining = deltaSeconds.clamp(0, 0.25).toDouble();
    while (remaining > 0) {
      final step = min(remaining, config.maximumUpdateStep);
      _updateStep(step);
      remaining -= step;
      if (score >= config.winningScore) break;
    }
  }

  void _updateStep(double deltaSeconds) {
    elapsedSeconds += deltaSeconds;
    _spawnElapsed += deltaSeconds;
    while (_spawnElapsed >= config.spawnIntervalSeconds) {
      _spawnElapsed -= config.spawnIntervalSeconds;
      _spawnTarget();
    }

    for (final target in targets) {
      target.x += target.direction * config.targetSpeed * deltaSeconds;
    }
    for (final projectile in projectiles) {
      projectile.x += projectile.velocityX * deltaSeconds;
      projectile.y += projectile.velocityY * deltaSeconds;
    }
    _resolveCollisions();
    targets.removeWhere(
      (target) =>
          target.x > width + config.targetWidth ||
          target.x + config.targetWidth < 0,
    );
    final radius = config.projectileSize / 2;
    projectiles.removeWhere(
      (projectile) =>
          projectile.x + radius < 0 ||
          projectile.x - radius > width ||
          projectile.y + radius < 0 ||
          projectile.y - radius > height,
    );
  }

  void _spawnTarget() {
    if (width <= 0 || height <= 0) return;
    final direction = random.nextBool() ? 1 : -1;
    final lane = direction == 1 ? 0 : 1;
    final word = words[random.nextInt(words.length)];
    final vowelIndices = [
      for (var index = 0; index < word.word.length; index++)
        if (letters.contains(word.word[index])) index,
    ];
    targets.add(
      LetterTarget(
        entityId: _nextEntityId++,
        word: word,
        missingIndex: vowelIndices[random.nextInt(vowelIndices.length)],
        x: direction == 1 ? -config.targetWidth : width,
        y:
            config.targetTopPadding +
            lane * (config.targetHeight + config.targetLaneGap),
        direction: direction,
      ),
    );
  }

  void _resolveCollisions() {
    final removedTargets = <int>{};
    final removedProjectiles = <int>{};
    final projectileRadius = config.projectileSize / 2;
    for (final projectile in projectiles) {
      final projectileBounds = GameRect(
        projectile.x - projectileRadius,
        projectile.y - projectileRadius,
        config.projectileSize,
        config.projectileSize,
      );
      for (final target in targets) {
        if (target.isSolved || removedTargets.contains(target.entityId)) {
          continue;
        }
        final targetBounds = GameRect(
          target.x,
          target.y,
          config.targetWidth,
          config.targetHeight,
        );
        if (!projectileBounds.overlaps(targetBounds)) continue;

        removedProjectiles.add(projectile.entityId);
        if (projectile.letter == target.missingLetter) {
          target.isSolved = true;
          if (score < config.winningScore) score++;
        } else {
          removedTargets.add(target.entityId);
        }
        break;
      }
    }
    targets.removeWhere((target) => removedTargets.contains(target.entityId));
    projectiles.removeWhere(
      (projectile) => removedProjectiles.contains(projectile.entityId),
    );
  }
}
