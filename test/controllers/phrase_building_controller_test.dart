import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/audio/asset_audio_player.dart';
import 'package:literacy_game/controllers/phrase_building_controller.dart';
import 'package:literacy_game/models/phrase_building_state.dart';
import 'package:literacy_game/models/sentence.dart';

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
  test(
    'moves words between pools and advances after a correct sentence',
    () async {
      final audioPlayer = _FakeAudioPlayer();
      final controller = PhraseBuildingController(
        audioPlayer,
        sentences: const [
          Sentence(id: 1, string: 'red bird', audioPath: 'first.mp3'),
          Sentence(id: 2, string: 'blue fish', audioPath: 'second.mp3'),
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
        Sentence(id: 1, string: 'red bird', audioPath: 'first.mp3'),
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
}
