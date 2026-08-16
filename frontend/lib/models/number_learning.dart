enum NumberRange { oneToSix, sevenToTwelve }

enum NumberLearningState { playing, correct, won }

class NumberLearningConfig {
  final int winningScore;
  final Duration successFeedbackDuration;

  const NumberLearningConfig({
    this.winningScore = 10,
    this.successFeedbackDuration = const Duration(seconds: 1),
  });
}
