enum ElementaryOperator { addition, subtraction, multiplication, division }

enum OperationsRange { oneToTwelve, oneToTwentyFour }

enum OperationsPracticeState { playing, correct, won }

class OperationsPracticeConfig {
  final int winningScore;
  final int maximumOperand;
  final int multiplicationUnitWeight;
  final int multiplicationNonUnitWeight;
  final Duration successFeedbackDuration;

  const OperationsPracticeConfig({
    this.winningScore = 10,
    this.maximumOperand = 99,
    this.multiplicationUnitWeight = 1,
    this.multiplicationNonUnitWeight = 6,
    this.successFeedbackDuration = const Duration(seconds: 1),
  }) : assert(multiplicationUnitWeight > 0),
       assert(multiplicationNonUnitWeight > 0);
}

class ElementaryEquation {
  final int left;
  final ElementaryOperator operator;
  final int right;
  final int answer;

  const ElementaryEquation({
    required this.left,
    required this.operator,
    required this.right,
    required this.answer,
  });
}
