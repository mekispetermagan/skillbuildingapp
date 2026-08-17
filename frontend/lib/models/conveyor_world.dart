import 'dart:math';

import 'conveyor_config.dart';
import 'conveyor_geometry.dart';
import 'image_word.dart';

class ConveyorShelf {
  final int id;
  final ImageWord word;
  final List<int> missingIndices;
  final Set<int> recoveredIndices = {};
  double y;

  ConveyorShelf({
    required this.id,
    required this.word,
    required this.missingIndices,
    required this.y,
  });

  bool get isComplete => recoveredIndices.length == missingIndices.length;

  String get displayWord {
    final text = word.uppercaseWord;
    final buffer = StringBuffer();
    for (var index = 0; index < text.length; index++) {
      final hidden =
          missingIndices.contains(index) && !recoveredIndices.contains(index);
      buffer.write(hidden ? '❓' : text[index]);
    }
    return buffer.toString();
  }

  int firstAvailableMatch(String letter) {
    for (final index in missingIndices) {
      if (!recoveredIndices.contains(index) &&
          word.uppercaseWord[index] == letter) {
        return index;
      }
    }
    return -1;
  }
}

class ConveyorLetter {
  final int id;
  String letter;
  double y;
  bool isDragging = false;

  ConveyorLetter({required this.id, required this.letter, required this.y});
}

enum ConveyorDropResult { matched, completed, wrong, ignored }

class ConveyorWorld implements ConveyorGeometry {
  final List<ImageWord> words;
  @override
  final ConveyorConfig config;
  final Random random;
  final List<ConveyorShelf> shelves = [];
  final List<ConveyorLetter> letters = [];

  @override
  double width = 0;
  @override
  double height = 0;
  int score = 0;
  late int lives;
  ConveyorDifficulty difficulty = ConveyorDifficulty.easy;

  int _nextId = 0;
  int _nextLetterIndex = 0;
  List<ImageWord> _deck = [];
  int _deckIndex = 0;

  ConveyorWorld({
    required List<ImageWord> words,
    required this.config,
    Random? random,
  }) : words = List.unmodifiable(words),
       random = random ?? Random() {
    if (words.isEmpty) {
      throw ArgumentError.value(words, 'words', 'Must not be empty');
    }
    reset();
  }

  @override
  double get leftBeltX => config.outerPadding;
  @override
  double get rightBeltX => width - config.outerPadding - config.rightBeltWidth;
  @override
  double get leftBeltWidth => min(
    config.leftBeltWidth,
    max(
      140,
      width - config.outerPadding * 2 - config.rightBeltWidth - config.beltGap,
    ),
  );

  void resize(double nextWidth, double nextHeight) {
    final firstLayout = width == 0 || height == 0;
    width = nextWidth;
    height = nextHeight;
    if (firstLayout && width > 0 && height > 0) _populate();
  }

  void reset() {
    shelves.clear();
    letters.clear();
    score = 0;
    lives = config.startingLives;
    _nextId = 0;
    _nextLetterIndex = 0;
    _deck = [...words]..shuffle(random);
    _deckIndex = 0;
    if (width > 0 && height > 0) _populate();
  }

  void setDifficulty(ConveyorDifficulty value) {
    if (difficulty == value) return;
    difficulty = value;
    _regenerateBelts();
  }

  void update(double deltaSeconds) {
    var remaining = deltaSeconds.clamp(0, 0.25).toDouble();
    while (remaining > 0 && score < config.winningScore && lives > 0) {
      final step = min(remaining, config.maximumUpdateStep);
      _updateStep(step);
      remaining -= step;
    }
  }

  void setDragging(int letterId, bool value) {
    final letter = _letterById(letterId);
    if (letter != null) letter.isDragging = value;
  }

  ConveyorDropResult drop({required int letterId, required int shelfId}) {
    final letter = _letterById(letterId);
    final shelf = _shelfById(shelfId);
    if (letter == null || shelf == null || shelf.isComplete) {
      if (letter != null) letter.isDragging = false;
      return ConveyorDropResult.ignored;
    }

    final matchIndex = shelf.firstAvailableMatch(letter.letter);
    if (matchIndex == -1) {
      letter.isDragging = false;
      _recycleLetter(letter);
      lives = max(0, lives - 1);
      return ConveyorDropResult.wrong;
    }

    shelf.recoveredIndices.add(matchIndex);
    letter.isDragging = false;
    _recycleLetter(letter);
    if (shelf.isComplete) {
      score++;
      return ConveyorDropResult.completed;
    }
    return ConveyorDropResult.matched;
  }

  bool canAccept({required int letterId, required int shelfId}) {
    final letter = _letterById(letterId);
    final shelf = _shelfById(shelfId);
    return letter != null && shelf != null && !shelf.isComplete;
  }

  void _populate() {
    final shelfStride = config.shelfHeight + config.shelfGap;
    final shelfCount = max(2, (height / shelfStride).ceil() + 1);
    for (var index = 0; index < shelfCount; index++) {
      shelves.add(_newShelf(-config.shelfHeight + index * shelfStride));
    }

    final letterStride = config.letterSize + config.letterGap;
    final letterCount = max(3, (height / letterStride).ceil() + 1);
    for (var index = 0; index < letterCount; index++) {
      letters.add(
        ConveyorLetter(
          id: _nextId++,
          letter: _nextLetter(),
          y: height - config.letterSize - index * letterStride,
        ),
      );
    }
  }

  void _updateStep(double deltaSeconds) {
    for (final shelf in shelves) {
      shelf.y += config.leftBeltSpeed * deltaSeconds;
      if (shelf.y > height) _replaceShelf(shelf);
    }
    for (final letter in letters) {
      letter.y -= config.rightBeltSpeed * deltaSeconds;
      if (!letter.isDragging && letter.y + config.letterSize < 0) {
        _recycleLetter(letter);
      }
    }
  }

  ConveyorShelf _newShelf(double y) {
    final word = _nextWord();
    final indices = <int>[
      for (var index = 0; index < word.uppercaseWord.length; index++)
        if (word.uppercaseWord[index] != ' ') index,
    ]..shuffle(random);
    return ConveyorShelf(
      id: _nextId++,
      word: word,
      missingIndices:
          indices.take(difficulty == ConveyorDifficulty.easy ? 1 : 2).toList()
            ..sort(),
      y: y,
    );
  }

  void _regenerateBelts() {
    shelves.clear();
    letters.clear();
    _nextLetterIndex = 0;
    _deck = [...words]..shuffle(random);
    _deckIndex = 0;
    if (width > 0 && height > 0) _populate();
  }

  void _replaceShelf(ConveyorShelf shelf) {
    final highestY = shelves.map((item) => item.y).reduce(min);
    final replacement = _newShelf(
      highestY - config.shelfHeight - config.shelfGap,
    );
    final index = shelves.indexOf(shelf);
    shelves[index] = replacement;
  }

  ImageWord _nextWord() {
    if (_deckIndex == _deck.length) {
      _deck = [...words]..shuffle(random);
      _deckIndex = 0;
    }
    return _deck[_deckIndex++];
  }

  String _nextLetter({String? fallback}) {
    final required = <String>[
      for (final shelf in shelves)
        for (final index in shelf.missingIndices)
          if (!shelf.recoveredIndices.contains(index))
            shelf.word.uppercaseWord[index],
    ];
    if (required.isEmpty) {
      return fallback ??
          (throw StateError('A conveyor needs at least one initial gap.'));
    }
    final letter = required[_nextLetterIndex % required.length];
    _nextLetterIndex++;
    return letter;
  }

  void _recycleLetter(ConveyorLetter letter) {
    final lowestY = letters.isEmpty
        ? height
        : letters
              .where((item) => item.id != letter.id)
              .fold<double>(0, (lowest, item) => max(lowest, item.y));
    letter
      ..letter = _nextLetter(fallback: letter.letter)
      ..y = max(height, lowestY + config.letterSize + config.letterGap)
      ..isDragging = false;
  }

  ConveyorLetter? _letterById(int id) {
    for (final letter in letters) {
      if (letter.id == id) return letter;
    }
    return null;
  }

  ConveyorShelf? _shelfById(int id) {
    for (final shelf in shelves) {
      if (shelf.id == id) return shelf;
    }
    return null;
  }
}
