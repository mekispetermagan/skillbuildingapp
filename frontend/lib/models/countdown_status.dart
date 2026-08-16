class CountdownStatus {
  final int remainingMilliseconds;
  final int totalMilliseconds;
  final int dangerZoneMilliseconds;
  final bool isRunning;

  const CountdownStatus({
    required this.remainingMilliseconds,
    required this.totalMilliseconds,
    required this.dangerZoneMilliseconds,
    required this.isRunning,
  });

  int get remainingSeconds => (remainingMilliseconds / 1000).ceil();
  int get withinSecondMilliseconds => remainingMilliseconds % 1000;
  bool get isInDangerZone => remainingMilliseconds <= dangerZoneMilliseconds;
  bool get isFinished => remainingMilliseconds == 0;
}
