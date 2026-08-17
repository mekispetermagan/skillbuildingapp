import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/audio/asset_audio_player.dart';
import 'package:literacy_game/controllers/operations_practice_controller.dart';
import 'package:literacy_game/models/operations_practice.dart';

class _FakeAudioPlayer implements AssetAudioPlayer {
  final playedPaths = <String>[];

  @override
  Future<void> play(String assetPath) async => playedPaths.add(assetPath);

  @override
  Future<void> stop() async {}
}

const _config = OperationsPracticeConfig(
  winningScore: 1000,
  successFeedbackDuration: Duration.zero,
);

OperationsPracticeController _controller(_FakeAudioPlayer audio) =>
    OperationsPracticeController(audio, config: _config, random: Random(3));

void _expectValid(OperationsPracticeController controller) {
  final equation = controller.equation;
  expect(equation.answer, inInclusiveRange(1, controller.maximumAnswer));
  expect(equation.left, inInclusiveRange(1, 99));
  expect(equation.right, inInclusiveRange(1, 99));
  final result = switch (equation.operator) {
    ElementaryOperator.addition => equation.left + equation.right,
    ElementaryOperator.subtraction => equation.left - equation.right,
    ElementaryOperator.multiplication => equation.left * equation.right,
    ElementaryOperator.division => equation.left ~/ equation.right,
  };
  expect(result, equation.answer);
  if (equation.operator == ElementaryOperator.division) {
    expect(equation.left % equation.right, 0);
  }
}

void main() {
  test('starts with all operators, lower range, and colors enabled', () {
    final controller = _controller(_FakeAudioPlayer());

    expect(controller.operators, ElementaryOperator.values.toSet());
    expect(controller.range, OperationsRange.oneToTwelve);
    expect(controller.useColors, isTrue);
    expect(controller.choices, List.generate(12, (index) => index + 1));
    _expectValid(controller);
  });

  for (final operator in ElementaryOperator.values) {
    test('${operator.name} generates valid equations in both ranges', () async {
      final controller = _controller(_FakeAudioPlayer());
      controller.setOperators({operator});

      for (var count = 0; count < 20; count++) {
        _expectValid(controller);
        await controller.guess(controller.equation.answer);
      }

      controller.setRange(OperationsRange.oneToTwentyFour);
      expect(controller.choices, List.generate(24, (index) => index + 1));
      for (var count = 0; count < 20; count++) {
        _expectValid(controller);
        await controller.guess(controller.equation.answer);
      }
    });
  }

  test('refuses an empty operator selection', () {
    final controller = _controller(_FakeAudioPlayer());
    controller.setOperators({ElementaryOperator.addition});
    controller.setOperators({});
    expect(controller.operators, {ElementaryOperator.addition});
  });

  test(
    'multiplication strongly favors pairs without a factor of one',
    () async {
      final controller = _controller(_FakeAudioPlayer());
      controller
        ..setRange(OperationsRange.oneToTwentyFour)
        ..setOperators({ElementaryOperator.multiplication});
      var unitFactorCount = 0;
      const sampleSize = 400;

      for (var count = 0; count < sampleSize; count++) {
        final equation = controller.equation;
        if (equation.left == 1 || equation.right == 1) unitFactorCount++;
        await controller.guess(equation.answer);
      }

      expect(unitFactorCount, lessThan(sampleSize * 0.3));
    },
  );

  test('settings preserve rewards and regenerate where appropriate', () async {
    final controller = _controller(_FakeAudioPlayer());
    await controller.guess(controller.equation.answer);

    controller.setRange(OperationsRange.oneToTwentyFour);
    controller.setUseColors(false);
    controller.setOperators({ElementaryOperator.division});

    expect(controller.score, 1);
    expect(controller.useColors, isFalse);
    expect(controller.equation.operator, ElementaryOperator.division);
    _expectValid(controller);
  });

  test('wrong answers count and keep the same equation', () async {
    final audio = _FakeAudioPlayer();
    final controller = _controller(audio);
    final equation = controller.equation;
    final wrong = controller.choices.firstWhere((it) => it != equation.answer);

    await controller.guess(wrong);

    expect(controller.equation, same(equation));
    expect(controller.incorrectAttempts, 1);
    expect(controller.state, OperationsPracticeState.playing);
    expect(audio.playedPaths.last, 'assets/audio/letter_dragging/pop.wav');
  });

  test('ten correct answers win', () async {
    final controller = OperationsPracticeController(
      _FakeAudioPlayer(),
      config: const OperationsPracticeConfig(
        successFeedbackDuration: Duration.zero,
      ),
      random: Random(3),
    );

    for (var count = 0; count < 10; count++) {
      await controller.guess(controller.equation.answer);
    }

    expect(controller.score, 10);
    expect(controller.state, OperationsPracticeState.won);
  });
}
