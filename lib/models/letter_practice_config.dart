class LetterPracticeConfig {
  final double targetCellSize;
  final double sourceCellSize;
  final int winningScore;
  final Duration completionFeedbackDuration;

  const LetterPracticeConfig({
    required this.targetCellSize,
    required this.sourceCellSize,
    required this.winningScore,
    required this.completionFeedbackDuration,
  });
}
