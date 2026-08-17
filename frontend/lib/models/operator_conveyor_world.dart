import 'dart:math';

import 'conveyor_config.dart';
import 'conveyor_geometry.dart';

enum ArithmeticOperator {
  add('+'),
  subtract('−'),
  multiply('×'),
  divide('÷');

  final String symbol;
  const ArithmeticOperator(this.symbol);

  int? evaluate(int left, int right) => switch (this) {
    ArithmeticOperator.add => left + right,
    ArithmeticOperator.subtract => left - right,
    ArithmeticOperator.multiply => left * right,
    ArithmeticOperator.divide =>
      right != 0 && left % right == 0 ? left ~/ right : null,
  };
}

class OperatorEquation {
  final int left;
  final int right;
  final int result;
  const OperatorEquation({
    required this.left,
    required this.right,
    required this.result,
  });

  bool accepts(ArithmeticOperator operator) =>
      operator.evaluate(left, right) == result;
  String get display => '$left  …  $right = $result';
}

class OperatorConveyorShelf {
  final int id;
  final OperatorEquation equation;
  double y;
  bool isComplete = false;
  ArithmeticOperator? placedOperator;

  OperatorConveyorShelf({
    required this.id,
    required this.equation,
    required this.y,
  });

  String get display => isComplete
      ? '${equation.left}  ${placedOperator!.symbol}  ${equation.right} = ${equation.result}'
      : equation.display;
}

class OperatorConveyorTile {
  final int id;
  ArithmeticOperator operator;
  double y;
  bool isDragging = false;

  OperatorConveyorTile({
    required this.id,
    required this.operator,
    required this.y,
  });
}

enum OperatorConveyorDropResult { completed, wrong, ignored }

class OperatorConveyorWorld implements ConveyorGeometry {
  @override
  final ConveyorConfig config;
  final Random random;
  final List<OperatorConveyorShelf> shelves = [];
  final List<OperatorConveyorTile> operators = [];

  @override
  double width = 0;
  @override
  double height = 0;
  int score = 0;
  late int lives;
  ConveyorDifficulty difficulty = ConveyorDifficulty.easy;
  int _nextId = 0;
  int _nextOperatorIndex = 0;

  OperatorConveyorWorld({required this.config, Random? random})
    : random = random ?? Random() {
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
    operators.clear();
    score = 0;
    lives = config.startingLives;
    _nextId = 0;
    _nextOperatorIndex = 0;
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

  void setDragging(int operatorId, bool value) {
    final tile = _operatorById(operatorId);
    if (tile != null) tile.isDragging = value;
  }

  bool canAccept({required int operatorId, required int shelfId}) =>
      _operatorById(operatorId) != null &&
      (_shelfById(shelfId)?.isComplete == false);

  OperatorConveyorDropResult drop({
    required int operatorId,
    required int shelfId,
  }) {
    final tile = _operatorById(operatorId);
    final shelf = _shelfById(shelfId);
    if (tile == null || shelf == null || shelf.isComplete) {
      if (tile != null) tile.isDragging = false;
      return OperatorConveyorDropResult.ignored;
    }
    tile.isDragging = false;
    if (!shelf.equation.accepts(tile.operator)) {
      _recycleOperator(tile);
      lives = max(0, lives - 1);
      return OperatorConveyorDropResult.wrong;
    }
    shelf
      ..isComplete = true
      ..placedOperator = tile.operator;
    _recycleOperator(tile);
    score++;
    return OperatorConveyorDropResult.completed;
  }

  void _populate() {
    final shelfStride = config.shelfHeight + config.shelfGap;
    final shelfCount = max(2, (height / shelfStride).ceil() + 1);
    for (var index = 0; index < shelfCount; index++) {
      shelves.add(_newShelf(-config.shelfHeight + index * shelfStride));
    }
    final operatorStride = config.letterSize + config.letterGap;
    final operatorCount = max(4, (height / operatorStride).ceil() + 1);
    for (var index = 0; index < operatorCount; index++) {
      operators.add(
        OperatorConveyorTile(
          id: _nextId++,
          operator: _nextOperator(),
          y: height - config.letterSize - index * operatorStride,
        ),
      );
    }
  }

  void _updateStep(double deltaSeconds) {
    for (final shelf in shelves) {
      shelf.y += config.leftBeltSpeed * deltaSeconds;
      if (shelf.y > height) _replaceShelf(shelf);
    }
    for (final tile in operators) {
      if (tile.isDragging) continue;
      tile.y -= config.rightBeltSpeed * deltaSeconds;
      if (tile.y + config.letterSize < 0) _recycleOperator(tile);
    }
  }

  OperatorConveyorShelf _newShelf(double y) =>
      OperatorConveyorShelf(id: _nextId++, equation: _newEquation(), y: y);

  OperatorEquation _newEquation() {
    final operators = _activeOperators;
    final operator = operators[random.nextInt(operators.length)];
    final maximum = difficulty == ConveyorDifficulty.easy ? 20 : 30;
    return switch (operator) {
      ArithmeticOperator.add => () {
        final left = random.nextInt(maximum - 1) + 1;
        final right = random.nextInt(maximum - left) + 1;
        return OperatorEquation(left: left, right: right, result: left + right);
      }(),
      ArithmeticOperator.subtract => () {
        final result = random.nextInt(maximum - 1) + 1;
        final right = random.nextInt(maximum - result) + 1;
        return OperatorEquation(
          left: result + right,
          right: right,
          result: result,
        );
      }(),
      ArithmeticOperator.multiply => () {
        final left = random.nextInt(maximum ~/ 2) + 1;
        final right = random.nextInt(maximum ~/ left) + 1;
        return OperatorEquation(left: left, right: right, result: left * right);
      }(),
      ArithmeticOperator.divide => () {
        final right = random.nextInt(maximum ~/ 2) + 1;
        final result = random.nextInt(maximum ~/ right) + 1;
        return OperatorEquation(
          left: right * result,
          right: right,
          result: result,
        );
      }(),
    };
  }

  void _replaceShelf(OperatorConveyorShelf shelf) {
    final highestY = shelves.map((item) => item.y).reduce(min);
    shelves[shelves.indexOf(shelf)] = _newShelf(
      highestY - config.shelfHeight - config.shelfGap,
    );
  }

  ArithmeticOperator _nextOperator() {
    final operators = _activeOperators;
    final result = operators[_nextOperatorIndex % operators.length];
    _nextOperatorIndex++;
    return result;
  }

  List<ArithmeticOperator> get _activeOperators =>
      difficulty == ConveyorDifficulty.easy
      ? ArithmeticOperator.values.take(3).toList(growable: false)
      : ArithmeticOperator.values;

  void _regenerateBelts() {
    shelves.clear();
    operators.clear();
    _nextOperatorIndex = 0;
    if (width > 0 && height > 0) _populate();
  }

  void _recycleOperator(OperatorConveyorTile tile) {
    final lowestY = operators
        .where((item) => item.id != tile.id)
        .fold<double>(0, (lowest, item) => max(lowest, item.y));
    tile
      ..operator = _nextOperator()
      ..y = max(height, lowestY + config.letterSize + config.letterGap)
      ..isDragging = false;
  }

  OperatorConveyorTile? _operatorById(int id) {
    for (final tile in operators) {
      if (tile.id == id) return tile;
    }
    return null;
  }

  OperatorConveyorShelf? _shelfById(int id) {
    for (final shelf in shelves) {
      if (shelf.id == id) return shelf;
    }
    return null;
  }
}
