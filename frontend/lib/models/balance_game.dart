import 'dart:math' as math;

enum ScaleStatus { left, balanced, right }

enum BalanceGameState { playing, correct, incorrect, won }

class BalanceStone {
  final int id;
  final int weight;

  const BalanceStone({required this.id, required this.weight});
}

class BalancePosition {
  final double x;
  final double y;

  const BalancePosition(this.x, this.y);
}

class BalanceSize {
  final double width;
  final double height;

  const BalanceSize(this.width, this.height);
}

class BalanceAnimationCurve {
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  const BalanceAnimationCurve(this.x1, this.y1, this.x2, this.y2);
}

class BalanceGameConfig {
  final int minimumWeight;
  final int maximumWeight;
  final int goodsCount;
  final int shelfStoneCount;
  final int maximumSelectedStones;
  final int winningScore;
  final Duration feedbackDuration;
  final Duration outroAnimationDelay;
  final Duration outroAnimationDuration;
  final BalanceAnimationCurve outroAnimationCurve;
  final BalanceSize stageSize;
  final BalancePosition scalePosition;
  final BalanceSize scaleSize;
  final BalanceSize traySize;
  final BalanceSize handSize;
  final BalancePosition leftTrayPosition;
  final BalancePosition rightTrayPosition;
  final Map<ScaleStatus, double> leftTrayY;
  final Map<ScaleStatus, double> rightTrayY;
  final Map<ScaleStatus, double> handAngles;
  final BalancePosition shelfPosition;
  final BalanceSize shelfSize;
  final double itemScale;
  final List<BalancePosition> trayItemPositions;
  final List<BalancePosition> shelfItemPositions;
  final Map<int, BalanceSize> goodsSizes;
  final Map<int, BalanceSize> stoneSizes;

  const BalanceGameConfig({
    this.minimumWeight = 1,
    this.maximumWeight = 7,
    this.goodsCount = 3,
    this.shelfStoneCount = 5,
    this.maximumSelectedStones = 3,
    this.winningScore = 10,
    this.feedbackDuration = const Duration(seconds: 2),
    this.outroAnimationDelay = const Duration(milliseconds: 100),
    this.outroAnimationDuration = const Duration(milliseconds: 600),
    this.outroAnimationCurve = const BalanceAnimationCurve(0.42, 0, 0.58, 1),
    this.stageSize = const BalanceSize(480, 360),
    this.scalePosition = const BalancePosition(-15, -90),
    this.scaleSize = const BalanceSize(447.70612, 116.56497),
    this.traySize = const BalanceSize(176, 83.83331),
    this.handSize = const BalanceSize(34.30346, 10.15079),
    this.leftTrayPosition = const BalancePosition(-110, 0),
    this.rightTrayPosition = const BalancePosition(110, 0),
    this.leftTrayY = const {
      ScaleStatus.left: 60,
      ScaleStatus.balanced: 80,
      ScaleStatus.right: 100,
    },
    this.rightTrayY = const {
      ScaleStatus.left: 100,
      ScaleStatus.balanced: 80,
      ScaleStatus.right: 60,
    },
    this.handAngles = const {
      ScaleStatus.left: -5 * math.pi / 6,
      ScaleStatus.balanced: -math.pi / 2,
      ScaleStatus.right: -math.pi / 6,
    },
    this.shelfPosition = const BalancePosition(90, 150),
    this.shelfSize = const BalanceSize(310.31755, 84.20179),
    this.itemScale = 0.7,
    this.trayItemPositions = const [
      BalancePosition(-60, 2),
      BalancePosition(0, 2),
      BalancePosition(60, 3),
    ],
    this.shelfItemPositions = const [
      BalancePosition(-120, 2),
      BalancePosition(-60, 2),
      BalancePosition(0, 2),
      BalancePosition(60, 2),
      BalancePosition(120, 2),
    ],
    this.goodsSizes = const {
      1: BalanceSize(80.03312, 56.99542),
      2: BalanceSize(81.06126, 59.98051),
      3: BalanceSize(91.68901, 66.83828),
      4: BalanceSize(91.20824, 76.96986),
      5: BalanceSize(97.93901, 82.76466),
      6: BalanceSize(97.93965, 91.68114),
      7: BalanceSize(103.22831, 96.96956),
    },
    this.stoneSizes = const {
      1: BalanceSize(49.9739, 37.37758),
      2: BalanceSize(54.33803, 37.37758),
      3: BalanceSize(58.15529, 37.37758),
      4: BalanceSize(61.40673, 37.37758),
      5: BalanceSize(64.76375, 37.75987),
      6: BalanceSize(67.67949, 38.98343),
      7: BalanceSize(70.40436, 40.53266),
    },
  });
}
