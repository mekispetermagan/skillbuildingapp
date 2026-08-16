import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/audio/asset_audio_player.dart';
import 'package:literacy_game/controllers/number_comparison_controller.dart';
import 'package:literacy_game/models/number_comparison.dart';

class _FakeAudioPlayer implements AssetAudioPlayer {
  final playedPaths = <String>[];
  @override
  Future<void> play(String assetPath) async => playedPaths.add(assetPath);
  @override
  Future<void> stop() async {}
}

const _config = NumberComparisonConfig(successFeedbackDuration: Duration.zero);

NumberComparisonController _controller(_FakeAudioPlayer audio) =>
    NumberComparisonController(audio, config: _config, random: Random(3));

NumberRelation _correct(NumberComparisonController controller) =>
    controller.leftNumber < controller.rightNumber
    ? NumberRelation.lessThan
    : controller.leftNumber > controller.rightNumber
    ? NumberRelation.greaterThan
    : NumberRelation.equal;

void main() {
  test('starts with lower patterned quantities and different emojis', () {
    final controller = _controller(_FakeAudioPlayer());
    expect(controller.range, ComparisonRange.oneToSix);
    expect(controller.arrangement, NumberArrangement.pattern);
    expect(controller.leftNumber, inInclusiveRange(1, 6));
    expect(controller.rightNumber, inInclusiveRange(1, 6));
    expect(controller.leftEmoji, isNot(controller.rightEmoji));
  });

  test('scatter positions are stable and non-overlapping per side', () {
    final controller = _controller(_FakeAudioPlayer());
    controller.setRange(ComparisonRange.oneToTwelve);
    controller.setArrangement(NumberArrangement.scattered);
    expect(controller.leftPositions.toSet(), hasLength(controller.leftNumber));
    expect(
      controller.rightPositions.toSet(),
      hasLength(controller.rightNumber),
    );
    final allPositions = [
      ...controller.leftPositions,
      ...controller.rightPositions,
    ];
    expect(
      allPositions.every(
        (position) => {-2 / 3, 0.0, 2 / 3}.contains(position.$1),
      ),
      isTrue,
    );
    expect(
      allPositions.every(
        (position) =>
            {-5 / 6, -3 / 6, -1 / 6, 1 / 6, 3 / 6, 5 / 6}.contains(position.$2),
      ),
      isTrue,
    );
  });

  test('settings generate a new exercise without resetting rewards', () async {
    final controller = _controller(_FakeAudioPlayer());
    await controller.guess(_correct(controller));
    controller.setRange(ComparisonRange.oneToTwelve);
    expect(controller.score, 1);
    expect(controller.leftNumber, inInclusiveRange(1, 12));
    expect(controller.rightNumber, inInclusiveRange(1, 12));
  });

  test('wrong relation keeps the exercise available for retry', () async {
    final audio = _FakeAudioPlayer();
    final controller = _controller(audio);
    final left = controller.leftNumber;
    final right = controller.rightNumber;
    final wrong = NumberRelation.values.firstWhere(
      (relation) => relation != _correct(controller),
    );
    await controller.guess(wrong);
    expect((controller.leftNumber, controller.rightNumber), (left, right));
    expect(controller.incorrectAttempts, 1);
    expect(controller.state, NumberComparisonState.playing);
    expect(audio.playedPaths.last, 'assets/audio/letter_dragging/pop.wav');
  });

  test('ten correct comparisons win', () async {
    final controller = _controller(_FakeAudioPlayer());
    for (var count = 0; count < 10; count++) {
      await controller.guess(_correct(controller));
    }
    expect(controller.score, 10);
    expect(controller.state, NumberComparisonState.won);
  });
}
