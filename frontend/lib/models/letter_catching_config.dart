class LetterCatchingConfig {
  final double fallingSpeed;
  final double spawnIntervalSeconds;
  final double fallingLetterSize;
  final double paddleWidth;
  final double paddleHeight;
  final double paddleBottomPadding;
  final int poolSize;
  final int startingLives;
  final int winningScore;
  final double maximumUpdateStep;

  const LetterCatchingConfig({
    required this.fallingSpeed,
    required this.spawnIntervalSeconds,
    required this.fallingLetterSize,
    required this.paddleWidth,
    required this.paddleHeight,
    required this.paddleBottomPadding,
    required this.poolSize,
    required this.startingLives,
    required this.winningScore,
    required this.maximumUpdateStep,
  }) : assert(fallingSpeed >= 0),
       assert(spawnIntervalSeconds > 0),
       assert(fallingLetterSize > 0),
       assert(paddleWidth > 0),
       assert(paddleHeight > 0),
       assert(paddleBottomPadding >= 0),
       assert(poolSize > 0),
       assert(startingLives > 0),
       assert(winningScore > 0),
       assert(maximumUpdateStep > 0);
}
