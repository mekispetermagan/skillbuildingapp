class LetterShootingConfig {
  final double projectileSpeed;
  final double targetSpeed;
  final double spawnIntervalSeconds;
  final double projectileSize;
  final double sourceLetterSize;
  final double sourceLetterGap;
  final int sourceLetterColumns;
  final double targetWidth;
  final double targetHeight;
  final double targetLaneGap;
  final double targetTopPadding;
  final double cannonWidth;
  final double cannonHeight;
  final double cannonBottomClearance;
  final double maximumUpdateStep;
  final int winningScore;

  const LetterShootingConfig({
    required this.projectileSpeed,
    required this.targetSpeed,
    required this.spawnIntervalSeconds,
    required this.projectileSize,
    required this.sourceLetterSize,
    required this.sourceLetterGap,
    required this.sourceLetterColumns,
    required this.targetWidth,
    required this.targetHeight,
    required this.targetLaneGap,
    required this.targetTopPadding,
    required this.cannonWidth,
    required this.cannonHeight,
    required this.cannonBottomClearance,
    required this.maximumUpdateStep,
    required this.winningScore,
  });
}
