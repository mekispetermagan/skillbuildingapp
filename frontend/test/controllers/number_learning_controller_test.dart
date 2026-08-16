import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/audio/asset_audio_player.dart';
import 'package:literacy_game/controllers/number_learning_controller.dart';
import 'package:literacy_game/models/number_learning.dart';

class _FakeAudioPlayer implements AssetAudioPlayer {
  final playedPaths = <String>[];
  @override
  Future<void> play(String assetPath) async => playedPaths.add(assetPath);
  @override
  Future<void> stop() async {}
}

const _config = NumberLearningConfig(successFeedbackDuration: Duration.zero);

NumberLearningController _controller(_FakeAudioPlayer audio) =>
    NumberLearningController(audio, config: _config, random: Random(1));

void main() {
  test('starts in the lower range with colors enabled', () {
    final controller = _controller(_FakeAudioPlayer());
    expect(controller.range, NumberRange.oneToSix);
    expect(controller.useColors, isTrue);
    expect(controller.choices, [1, 2, 3, 4, 5, 6]);
    expect(controller.target, inInclusiveRange(1, 6));
    expect(numberEmojis, contains(controller.emoji));
  });

  test('range and color changes preserve earned rewards', () async {
    final controller = _controller(_FakeAudioPlayer());
    await controller.guess(controller.target);
    controller.setRange(NumberRange.sevenToTwelve);
    controller.setUseColors(false);
    expect(controller.score, 1);
    expect(controller.choices, [7, 8, 9, 10, 11, 12]);
    expect(controller.target, inInclusiveRange(7, 12));
    expect(controller.useColors, isFalse);
  });

  test('wrong answers count and keep the target', () async {
    final audio = _FakeAudioPlayer();
    final controller = _controller(audio);
    final target = controller.target;
    final wrong = controller.choices.firstWhere((number) => number != target);
    await controller.guess(wrong);
    expect(controller.target, target);
    expect(controller.score, 0);
    expect(controller.incorrectAttempts, 1);
    expect(audio.playedPaths.last, 'assets/audio/letter_dragging/pop.wav');
  });

  test('ten correct answers win', () async {
    final controller = _controller(_FakeAudioPlayer());
    for (var count = 0; count < 10; count++) {
      await controller.guess(controller.target);
    }
    expect(controller.score, 10);
    expect(controller.state, NumberLearningState.won);
  });
}
