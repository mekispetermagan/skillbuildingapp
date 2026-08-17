import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/audio/asset_audio_player.dart';
import 'package:literacy_game/controllers/countdown_controller.dart';
import 'package:literacy_game/controllers/number_dragging_controller.dart';
import 'package:literacy_game/models/letter_dragging_state.dart';
import 'package:literacy_game/models/number_dragging.dart';

class _FakeAudioPlayer implements AssetAudioPlayer {
  final playedPaths = <String>[];

  @override
  Future<void> play(String assetPath) async => playedPaths.add(assetPath);

  @override
  Future<void> stop() async {}
}

class _SequenceRandom implements Random {
  final List<int> values;
  int _index = 0;

  _SequenceRandom(this.values);

  @override
  int nextInt(int max) => values[_index++ % values.length] % max;

  @override
  bool nextBool() => nextInt(2) == 1;

  @override
  double nextDouble() => nextInt(1000) / 1000;
}

NumberDraggingController _controller({
  Random? random,
  _FakeAudioPlayer? audio,
}) => NumberDraggingController(
  audio ?? _FakeAudioPlayer(),
  random: random ?? Random(4),
  config: const NumberDraggingConfig(successFeedbackDuration: Duration.zero),
  countdown: CountdownController(
    totalDuration: const Duration(minutes: 2),
    dangerZone: const Duration(seconds: 15),
    tickInterval: const Duration(days: 1),
  ),
);

void _solve(NumberDraggingController controller) {
  final ordered = [...controller.tiles]
    ..sort((first, second) {
      final comparison = first.number.compareTo(second.number);
      return comparison != 0 ? comparison : first.id.compareTo(second.id);
    });
  for (final (targetIndex, target) in ordered.indexed) {
    final oldIndex = controller.tiles.indexWhere(
      (tile) => tile.id == target.id,
    );
    controller.reorder(oldIndex, targetIndex);
  }
}

void main() {
  test('creates seven identity-stable tiles and allows duplicate values', () {
    final controller = _controller(
      random: _SequenceRandom([3, 1, 3, 2, 1, 2, 1]),
    )..start();

    expect(controller.tiles, hasLength(7));
    expect(controller.tiles.map((tile) => tile.id).toSet(), hasLength(7));
    expect(
      controller.tiles.map((tile) => tile.number).toSet().length,
      lessThan(7),
    );
    controller.dispose();
  });

  test('accepts non-decreasing order and awards a gem', () async {
    final audio = _FakeAudioPlayer();
    final controller = _controller(audio: audio)..start();

    _solve(controller);
    expect(controller.state, LetterDraggingState.successFeedback);
    await Future<void>.delayed(Duration.zero);

    expect(controller.score, 1);
    expect(controller.state, LetterDraggingState.playing);
    expect(
      audio.playedPaths,
      contains('assets/audio/letter_dragging/correct.mp3'),
    );
    controller.dispose();
  });

  test('range changes preserve timed-session progress', () async {
    final controller = _controller()..start();
    _solve(controller);
    await Future<void>.delayed(Duration.zero);
    controller.pass();
    final remaining = controller.countdown.status.remainingMilliseconds;

    controller.setRange(NumberDraggingRange.oneToSixty);

    expect(controller.score, 1);
    expect(controller.passedItems, 1);
    expect(controller.maximumNumber, 60);
    expect(controller.tiles.every((tile) => tile.number <= 60), isTrue);
    expect(controller.countdown.status.remainingMilliseconds, remaining);
    controller.dispose();
  });

  test('shows results when the two-minute countdown ends', () {
    final audio = _FakeAudioPlayer();
    final controller = _controller(audio: audio)..start();

    controller.countdown.update(const Duration(minutes: 2));

    expect(controller.state, LetterDraggingState.result);
    expect(
      audio.playedPaths,
      contains('assets/audio/letter_dragging/fanfare.mp3'),
    );
    controller.dispose();
  });
}
