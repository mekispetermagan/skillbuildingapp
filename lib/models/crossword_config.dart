class CrosswordConfig {
  final double cellSize;
  final double alphabetCellSize;
  final int maximumGridSize;
  final double revealFraction;
  final int winningScore;
  final int generationAttempts;
  final Duration completedCrosswordDuration;

  const CrosswordConfig({
    required this.cellSize,
    required this.alphabetCellSize,
    required this.maximumGridSize,
    required this.revealFraction,
    required this.winningScore,
    required this.generationAttempts,
    required this.completedCrosswordDuration,
  });
}
