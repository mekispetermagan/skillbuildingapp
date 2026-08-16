enum ComparisonRange { oneToSix, oneToTwelve }

enum NumberArrangement { pattern, scattered }

enum NumberRelation { lessThan, equal, greaterThan }

enum NumberComparisonState { playing, correct, won }

class NumberComparisonConfig {
  final int winningScore;
  final Duration successFeedbackDuration;

  const NumberComparisonConfig({
    this.winningScore = 10,
    this.successFeedbackDuration = const Duration(seconds: 1),
  });
}
