enum NumberDraggingRange { oneToTwelve, oneToTwentyFour, oneToSixty }

class NumberDraggingConfig {
  final int itemCount;
  final Duration totalDuration;
  final Duration dangerZone;
  final Duration successFeedbackDuration;

  const NumberDraggingConfig({
    this.itemCount = 7,
    this.totalDuration = const Duration(minutes: 2),
    this.dangerZone = const Duration(seconds: 15),
    this.successFeedbackDuration = const Duration(milliseconds: 500),
  }) : assert(itemCount > 1);
}

class NumberDraggingTile {
  final int id;
  final int number;

  const NumberDraggingTile({required this.id, required this.number});
}
