class LetterLearningConfig {
  final double targetCellSize;
  final double sourceCellSize;
  final int winningScore;
  final Duration promptGap;
  final Duration successFeedbackDuration;

  const LetterLearningConfig({
    required this.targetCellSize,
    required this.sourceCellSize,
    required this.winningScore,
    required this.promptGap,
    required this.successFeedbackDuration,
  });
}
