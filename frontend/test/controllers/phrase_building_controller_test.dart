import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/audio/asset_audio_player.dart';
import 'package:skillbuilding_game/controllers/phrase_building_controller.dart';
import 'package:skillbuilding_game/models/phrase_building_state.dart';
import 'package:skillbuilding_game/models/sentence.dart';

class _FakeAudioPlayer implements AssetAudioPlayer {
  final playedPaths = <String>[];

  @override
  Future<void> play(String assetPath) async {
    playedPaths.add(assetPath);
  }

  @override
  Future<void> stop() async {}
}

void main() {
  test('directional moves append to the other pool only', () {
    final controller = PhraseBuildingController(
      _FakeAudioPlayer(),
      sentences: const [
        Sentence(id: 1, text: 'red bird', audioPath: 'first.mp3'),
      ],
      random: Random(1),
    );
    final red = controller.sourcePool.singleWhere((tile) => tile.word == 'red');

    expect(controller.canMoveToTarget(red), isTrue);
    expect(controller.canMoveToSource(red), isFalse);
    controller.moveToSource(red);
    expect(controller.sourcePool, contains(red));

    controller.moveToTarget(red);
    expect(controller.targetPool, [red]);
    expect(controller.canMoveToTarget(red), isFalse);
    expect(controller.canMoveToSource(red), isTrue);

    controller.moveToTarget(red);
    expect(controller.targetPool, [red]);
    controller.moveToSource(red);
    expect(controller.targetPool, isEmpty);
    expect(controller.sourcePool.last, red);
    controller.dispose();
  });

  test(
    'moves words between pools and advances after a correct sentence',
    () async {
      final audioPlayer = _FakeAudioPlayer();
      final controller = PhraseBuildingController(
        audioPlayer,
        sentences: const [
          Sentence(id: 1, text: 'red bird', audioPath: 'first.mp3'),
          Sentence(id: 2, text: 'blue fish', audioPath: 'second.mp3'),
        ],
        random: Random(1),
        feedbackDuration: Duration.zero,
      );

      for (final word in const ['red', 'bird']) {
        controller.move(
          controller.sourcePool.singleWhere((tile) => tile.word == word),
        );
      }

      await controller.submit();

      expect(controller.state, PhraseBuildingState.guessing);
      expect(controller.targetPool, isEmpty);
      expect(
        controller.sourcePool.map((tile) => tile.word),
        unorderedEquals(['blue', 'fish']),
      );
      expect(audioPlayer.playedPaths, ['second.mp3']);
    },
  );

  test('keeps the sentence after an incorrect submission', () async {
    final controller = PhraseBuildingController(
      _FakeAudioPlayer(),
      sentences: const [
        Sentence(id: 1, text: 'red bird', audioPath: 'first.mp3'),
      ],
      random: Random(1),
      feedbackDuration: Duration.zero,
    );

    controller.move(
      controller.sourcePool.singleWhere((tile) => tile.word == 'bird'),
    );
    await controller.submit();

    expect(controller.state, PhraseBuildingState.guessing);
    expect(controller.targetPool.single.word, 'bird');
  });

  test('restart invalidates feedback from the previous session', () async {
    final controller = PhraseBuildingController(
      _FakeAudioPlayer(),
      sentences: const [
        Sentence(id: 1, text: 'red bird', audioPath: 'first.mp3'),
      ],
      random: Random(1),
      feedbackDuration: const Duration(milliseconds: 10),
    );
    controller.move(
      controller.sourcePool.singleWhere((tile) => tile.word == 'bird'),
    );
    final submission = controller.submit();

    controller.start();
    await submission;

    expect(controller.state, PhraseBuildingState.guessing);
    expect(controller.targetPool, isEmpty);
    expect(controller.sourcePool, hasLength(2));
  });

  test(
    'wins after ten correct sentences and restart resets the score',
    () async {
      final controller = PhraseBuildingController(
        _FakeAudioPlayer(),
        sentences: const [
          Sentence(id: 1, text: 'red bird', audioPath: 'first.mp3'),
        ],
        random: Random(1),
        feedbackDuration: Duration.zero,
      );

      for (var answer = 0; answer < phraseBuildingWinningScore; answer++) {
        for (final word in const ['red', 'bird']) {
          controller.move(
            controller.sourcePool.singleWhere((tile) => tile.word == word),
          );
        }
        await controller.submit();
      }

      expect(controller.score, phraseBuildingWinningScore);
      expect(controller.state, PhraseBuildingState.won);
      expect(controller.canMove, isFalse);
      expect(controller.canSubmit, isFalse);

      controller.start();

      expect(controller.score, 0);
      expect(controller.state, PhraseBuildingState.guessing);
      controller.dispose();
    },
  );
}
