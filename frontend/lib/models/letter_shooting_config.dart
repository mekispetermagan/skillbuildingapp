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
  }) : assert(projectileSpeed >= 0),
       assert(targetSpeed >= 0),
       assert(spawnIntervalSeconds > 0),
       assert(projectileSize > 0),
       assert(sourceLetterSize > 0),
       assert(sourceLetterGap >= 0),
       assert(sourceLetterColumns > 0),
       assert(targetWidth > 0),
       assert(targetHeight > 0),
       assert(targetLaneGap >= 0),
       assert(targetTopPadding >= 0),
       assert(cannonWidth > 0),
       assert(cannonHeight > 0),
       assert(cannonBottomClearance >= 0),
       assert(maximumUpdateStep > 0),
       assert(winningScore > 0);
}
