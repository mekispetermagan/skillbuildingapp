import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/audio/asset_audio_player.dart';
import 'package:literacy_game/controllers/countdown_controller.dart';
import 'package:literacy_game/controllers/letter_dragging_controller.dart';
import 'package:literacy_game/models/letter_dragging_state.dart';
import 'package:literacy_game/models/letter_dragging_word.dart';

class _FakeAudioPlayer implements AssetAudioPlayer {
  final playedPaths = <String>[];

  @override
  Future<void> play(String assetPath) async {
    playedPaths.add(assetPath);
  }

  @override
  Future<void> stop() async {}
}

LetterDraggingController _controller({
  List<LetterDraggingWord> words = const [
    LetterDraggingWord(id: 1, word: 'ZEBRA'),
  ],
  _FakeAudioPlayer? audioPlayer,
  Duration successFeedbackDuration = Duration.zero,
}) {
  return LetterDraggingController(
    audioPlayer ?? _FakeAudioPlayer(),
    words: words,
    random: Random(4),
    countdown: CountdownController(
      totalDuration: const Duration(minutes: 2),
      dangerZone: const Duration(seconds: 15),
      tickInterval: const Duration(days: 1),
    ),
    successFeedbackDuration: successFeedbackDuration,
  );
}

String _solution(LetterDraggingController controller) {
  final ordered = [...controller.tiles]..sort((a, b) => a.id.compareTo(b.id));
  return ordered.map((tile) => tile.letter).join();
}

void _solve(LetterDraggingController controller) {
  for (
    var targetIndex = 0;
    targetIndex < controller.tiles.length;
    targetIndex++
  ) {
    final oldIndex = controller.tiles.indexWhere(
      (tile) => tile.id == targetIndex,
    );
    controller.reorder(oldIndex, targetIndex);
  }
}

void main() {
  test('starts with a shuffled word and awards a gem when solved', () async {
    final audioPlayer = _FakeAudioPlayer();
    final controller = _controller(audioPlayer: audioPlayer)..start();

    expect(controller.tiles.map((tile) => tile.letter).join(), isNot('ZEBRA'));

    _solve(controller);
    expect(controller.state, LetterDraggingState.successFeedback);
    await Future<void>.delayed(Duration.zero);

    expect(controller.score, 1);
    expect(controller.state, LetterDraggingState.playing);
    expect(
      audioPlayer.playedPaths,
      contains('assets/audio/letter_dragging/correct.mp3'),
    );
    controller.dispose();
  });

  test('an unsolved move remains immediately playable', () {
    final controller = _controller()..start();

    controller.reorder(0, 0);

    expect(controller.state, LetterDraggingState.playing);
    expect(controller.canReorder, isTrue);
    controller.dispose();
  });

  test('uses every word before starting another shuffled deck', () {
    final controller = _controller(
      words: const [
        LetterDraggingWord(id: 1, word: 'LION'),
        LetterDraggingWord(id: 2, word: 'ZEBRA'),
        LetterDraggingWord(id: 3, word: 'CRANE'),
      ],
    )..start();
    final seen = <String>{};

    for (var index = 0; index < 3; index++) {
      seen.add(_solution(controller));
      controller.pass();
    }

    expect(seen, {'LION', 'ZEBRA', 'CRANE'});
    controller.dispose();
  });

  test('keeps repeated letters as distinct draggable tiles', () {
    final controller = _controller(
      words: const [LetterDraggingWord(id: 1, word: 'BALLOON')],
    )..start();

    expect(controller.tiles.map((tile) => tile.id).toSet(), hasLength(7));
    controller.dispose();
  });

  test('shows results when the countdown ends', () {
    final audioPlayer = _FakeAudioPlayer();
    final controller = _controller(audioPlayer: audioPlayer)..start();

    controller.countdown.update(const Duration(minutes: 2));

    expect(controller.state, LetterDraggingState.result);
    expect(
      audioPlayer.playedPaths,
      contains('assets/audio/letter_dragging/fanfare.mp3'),
    );
    controller.dispose();
  });

  test('restart invalidates completion from the previous session', () async {
    final controller = _controller(
      successFeedbackDuration: const Duration(milliseconds: 10),
    )..start();
    _solve(controller);

    controller.start();
    await Future<void>.delayed(const Duration(milliseconds: 15));

    expect(controller.score, 0);
    expect(controller.state, LetterDraggingState.playing);
    controller.dispose();
  });
}
