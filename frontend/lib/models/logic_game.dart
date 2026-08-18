enum LogicDifficulty { easy, medium, hard }

enum LogicPropertyKind { character, color, sunglasses, bicycle }

enum LogicGameState { playing, exerciseFeedback, won }

class LogicProperty {
  final LogicPropertyKind kind;
  final int value;

  const LogicProperty({required this.kind, required this.value});

  bool matches(LogicObject object) => switch (kind) {
    LogicPropertyKind.character => object.character == value,
    LogicPropertyKind.color => object.color == value,
    LogicPropertyKind.sunglasses => object.hasSunglasses,
    LogicPropertyKind.bicycle => object.hasBicycle,
  };
}

class LogicObject {
  final int id;
  final int character;
  final int color;
  final bool hasSunglasses;
  final bool hasBicycle;

  const LogicObject({
    required this.id,
    required this.character,
    required this.color,
    required this.hasSunglasses,
    required this.hasBicycle,
  });

  String get assetCode =>
      '$character$color${hasSunglasses ? 1 : 0}${hasBicycle ? 1 : 0}';
}

class LogicPoint {
  final double x;
  final double y;

  const LogicPoint(this.x, this.y);
}

class LogicPlacement {
  final int objectId;
  final LogicPoint position;
  final bool isCorrect;

  const LogicPlacement({
    required this.objectId,
    required this.position,
    required this.isCorrect,
  });
}

class LogicCircle {
  final LogicPoint center;
  final double radius;

  const LogicCircle({required this.center, required this.radius});
}

class LogicDiagramGeometry {
  final double width;
  final double height;
  final List<LogicCircle> circles;

  const LogicDiagramGeometry({
    required this.width,
    required this.height,
    required this.circles,
  });
}

class LogicGameConfig {
  final int objectCount;
  final int winningScore;
  final Duration exerciseFeedbackDuration;
  final double diagramAspectRatio;
  final double circleRadiusHeightFactor;
  final double easyCenterYFactor;
  final double mediumCenterYFactor;
  final double hardUpperCenterYFactor;
  final double labelGap;
  final double labelSize;
  final double objectSize;

  const LogicGameConfig({
    this.objectCount = 5,
    this.winningScore = 10,
    this.exerciseFeedbackDuration = const Duration(seconds: 2),
    this.diagramAspectRatio = 1.0,
    this.circleRadiusHeightFactor = 0.2,
    this.easyCenterYFactor = 0.55,
    this.mediumCenterYFactor = 0.55,
    this.hardUpperCenterYFactor = 0.38,
    this.labelGap = 8,
    this.labelSize = 52,
    this.objectSize = 68,
  });

  int propertyCount(LogicDifficulty difficulty) => switch (difficulty) {
    LogicDifficulty.easy => 1,
    LogicDifficulty.medium => 2,
    LogicDifficulty.hard => 3,
  };

  LogicDiagramGeometry geometry({
    required LogicDifficulty difficulty,
    required double width,
    required double height,
  }) {
    final radius = height * circleRadiusHeightFactor;
    final middleX = width / 2;
    final circles = switch (difficulty) {
      LogicDifficulty.easy => [
        LogicCircle(
          center: LogicPoint(middleX, height * easyCenterYFactor),
          radius: radius,
        ),
      ],
      LogicDifficulty.medium => [
        LogicCircle(
          center: LogicPoint(
            middleX - radius / 2,
            height * mediumCenterYFactor,
          ),
          radius: radius,
        ),
        LogicCircle(
          center: LogicPoint(
            middleX + radius / 2,
            height * mediumCenterYFactor,
          ),
          radius: radius,
        ),
      ],
      LogicDifficulty.hard => [
        LogicCircle(
          center: LogicPoint(
            middleX - radius / 2,
            height * hardUpperCenterYFactor,
          ),
          radius: radius,
        ),
        LogicCircle(
          center: LogicPoint(
            middleX + radius / 2,
            height * hardUpperCenterYFactor,
          ),
          radius: radius,
        ),
        LogicCircle(
          center: LogicPoint(
            middleX,
            height * hardUpperCenterYFactor + 0.8660254038 * radius,
          ),
          radius: radius,
        ),
      ],
    };
    return LogicDiagramGeometry(width: width, height: height, circles: circles);
  }
}
