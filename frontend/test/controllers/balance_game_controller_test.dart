import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/audio/asset_audio_player.dart';
import 'package:literacy_game/controllers/balance_game_controller.dart';
import 'package:literacy_game/models/balance_game.dart';

class _FakeAudioPlayer implements AssetAudioPlayer {
  final playedPaths = <String>[];

  @override
  Future<void> play(String assetPath) async => playedPaths.add(assetPath);

  @override
  Future<void> stop() async {}
}

void main() {
  test('creates a left load and a five-stone solvable shelf', () {
    final controller = BalanceGameController(
      _FakeAudioPlayer(),
      random: Random(1),
    );

    expect(controller.goodsWeights, hasLength(3));
    expect(controller.shelfStones, hasLength(5));
    expect(
      controller.shelfStones.map((stone) => stone.id).toSet(),
      hasLength(5),
    );
    expect(controller.selectedStones, isEmpty);
    expect(controller.scaleStatus, ScaleStatus.left);
    expect(_solutions(controller), isNotEmpty);
  });

  test('moves a selected shelf stone to the right tray', () async {
    final controller = BalanceGameController(
      _FakeAudioPlayer(),
      random: Random(2),
    );
    final stone = controller.shelfStones.first;

    await controller.selectStone(stone.id);

    if (controller.state == BalanceGameState.playing) {
      expect(controller.selectedStones, [stone]);
      expect(controller.rightWeight, stone.weight);
    }
  });

  test('accepts any shelf subset that balances the scale', () async {
    final audio = _FakeAudioPlayer();
    final controller = BalanceGameController(
      audio,
      config: const BalanceGameConfig(
        winningScore: 1,
        feedbackDuration: Duration.zero,
        outroAnimationDuration: Duration.zero,
      ),
      random: Random(3),
    );
    final solution = _solutions(controller).first;

    for (final stone in solution) {
      await controller.selectStone(stone.id);
    }

    expect(controller.state, BalanceGameState.won);
    expect(controller.score, 1);
    expect(controller.incorrectAttempts, 0);
    expect(audio.playedPaths.single, contains('correct'));
  });

  test(
    'three stones with the wrong total count as one failed attempt',
    () async {
      final audio = _FakeAudioPlayer();
      late BalanceGameController controller;
      late List<BalanceStone> failure;
      for (var seed = 0; seed < 100; seed++) {
        controller = BalanceGameController(
          audio,
          config: const BalanceGameConfig(
            feedbackDuration: Duration.zero,
            outroAnimationDuration: Duration.zero,
          ),
          random: Random(seed),
        );
        failure = _failureSequence(controller);
        if (failure.isNotEmpty) break;
      }
      expect(failure, isNotEmpty);

      for (final stone in failure) {
        await controller.selectStone(stone.id);
      }

      expect(controller.state, BalanceGameState.playing);
      expect(controller.score, 0);
      expect(controller.incorrectAttempts, 1);
      expect(audio.playedPaths.single, contains('pop'));
    },
  );
}

List<List<BalanceStone>> _solutions(BalanceGameController controller) {
  final stones = controller.shelfStones;
  final result = <List<BalanceStone>>[];
  for (var first = 0; first < stones.length; first++) {
    for (var second = first; second < stones.length; second++) {
      for (var third = second; third < stones.length; third++) {
        final indices = {first, second, third};
        final choice = [for (final index in indices) stones[index]];
        if (choice.fold(0, (sum, stone) => sum + stone.weight) ==
            controller.leftWeight) {
          result.add(choice);
        }
      }
    }
  }
  return result;
}

List<BalanceStone> _failureSequence(BalanceGameController controller) {
  final stones = controller.shelfStones;
  for (final first in stones) {
    if (first.weight >= controller.leftWeight) continue;
    for (final second in stones.where((stone) => stone.id != first.id)) {
      final twoTotal = first.weight + second.weight;
      if (twoTotal >= controller.leftWeight) continue;
      for (final third in stones.where(
        (stone) => stone.id != first.id && stone.id != second.id,
      )) {
        if (twoTotal + third.weight != controller.leftWeight) {
          return [first, second, third];
        }
      }
    }
  }
  return const [];
}
