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
  });
}
