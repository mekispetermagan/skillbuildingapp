import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/countdown_status.dart';

class CountdownController extends ChangeNotifier {
  final Duration totalDuration;
  final Duration dangerZone;
  final Duration tickInterval;

  late CountdownStatus _status;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  CountdownController({
    required this.totalDuration,
    required this.dangerZone,
    this.tickInterval = const Duration(milliseconds: 50),
  }) {
    if (totalDuration <= Duration.zero ||
        dangerZone < Duration.zero ||
        dangerZone >= totalDuration) {
      throw ArgumentError('Invalid countdown durations.');
    }
    _status = _createStatus(totalDuration, false);
  }

  CountdownStatus get status => _status;

  void start() {
    _timer?.cancel();
    _stopwatch
      ..reset()
      ..start();
    _status = _createStatus(totalDuration, true);
    _timer = Timer.periodic(tickInterval, (_) => update(_stopwatch.elapsed));
    notifyListeners();
  }

  void update(Duration elapsed) {
    if (!_status.isRunning) return;

    final remaining = totalDuration - elapsed;
    if (remaining <= Duration.zero) {
      _timer?.cancel();
      _timer = null;
      _stopwatch.stop();
      _status = _createStatus(Duration.zero, false);
    } else {
      _status = _createStatus(remaining, true);
    }
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
    if (!_status.isRunning) return;
    _status = CountdownStatus(
      remainingMilliseconds: _status.remainingMilliseconds,
      totalMilliseconds: _status.totalMilliseconds,
      dangerZoneMilliseconds: _status.dangerZoneMilliseconds,
      isRunning: false,
    );
    notifyListeners();
  }

  CountdownStatus _createStatus(Duration remaining, bool isRunning) =>
      CountdownStatus(
        remainingMilliseconds: remaining.inMilliseconds,
        totalMilliseconds: totalDuration.inMilliseconds,
        dangerZoneMilliseconds: dangerZone.inMilliseconds,
        isRunning: isRunning,
      );

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}
