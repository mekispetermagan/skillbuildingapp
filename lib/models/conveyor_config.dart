class ConveyorConfig {
  final double leftBeltWidth;
  final double rightBeltWidth;
  final double beltGap;
  final double outerPadding;
  final double shelfHeight;
  final double shelfGap;
  final double letterSize;
  final double letterGap;
  final double leftBeltSpeed;
  final double rightBeltSpeed;
  final int startingLives;
  final int winningScore;
  final double maximumUpdateStep;

  const ConveyorConfig({
    required this.leftBeltWidth,
    required this.rightBeltWidth,
    required this.beltGap,
    required this.outerPadding,
    required this.shelfHeight,
    required this.shelfGap,
    required this.letterSize,
    required this.letterGap,
    required this.leftBeltSpeed,
    required this.rightBeltSpeed,
    required this.startingLives,
    required this.winningScore,
    required this.maximumUpdateStep,
  });
}
