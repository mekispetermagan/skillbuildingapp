class EvenOddConfig {
  final double fallingSpeed;
  final double spawnIntervalSeconds;
  final double fallingNumberSize;
  final double paddleWidth;
  final double paddleHeight;
  final double paddleBottomPadding;
  final int maximumNumber;
  final int startingLives;
  final int winningScore;
  final double maximumUpdateStep;

  const EvenOddConfig({
    required this.fallingSpeed,
    required this.spawnIntervalSeconds,
    required this.fallingNumberSize,
    required this.paddleWidth,
    required this.paddleHeight,
    required this.paddleBottomPadding,
    required this.maximumNumber,
    required this.startingLives,
    required this.winningScore,
    required this.maximumUpdateStep,
  }) : assert(fallingSpeed >= 0),
       assert(spawnIntervalSeconds > 0),
       assert(fallingNumberSize > 0),
       assert(paddleWidth > 0),
       assert(paddleHeight > 0),
       assert(paddleBottomPadding >= 0),
       assert(maximumNumber > 0),
       assert(startingLives > 0),
       assert(winningScore > 0),
       assert(maximumUpdateStep > 0);
}
