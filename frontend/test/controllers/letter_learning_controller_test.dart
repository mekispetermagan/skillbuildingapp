import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/audio/asset_audio_player.dart';
import 'package:skillbuilding_game/controllers/letter_learning_controller.dart';
import 'package:skillbuilding_game/models/alphabet_letter.dart';
import 'package:skillbuilding_game/models/alphabet_object.dart';
import 'package:skillbuilding_game/models/letter_learning_config.dart';
import 'package:skillbuilding_game/models/letter_learning_state.dart';

class _FakeAudioPlayer implements AssetAudioPlayer {
  final playedPaths = <String>[];

  @override
  Future<void> play(String assetPath) async => playedPaths.add(assetPath);

  @override
  Future<void> stop() async {}
}

const _alphabet = [
  AlphabetLetter(
    id: 1,
    letter: 'A',
    colorName: 'red',
    tier: 1,
    audioPath: 'A.mp3',
  ),
  AlphabetLetter(
    id: 2,
    letter: 'M',
    colorName: 'orange',
    tier: 1,
    audioPath: 'M.mp3',
  ),
  AlphabetLetter(
    id: 3,
    letter: 'L',
    colorName: 'blue',
    tier: 2,
    audioPath: 'L.mp3',
  ),
];

const _objects = [
  AlphabetObject(
    id: 1,
    letter: 'A',
    word: 'apple',
    audioPath: 'apple.mp3',
    imagePath: 'apple.png',
  ),
  AlphabetObject(
    id: 2,
    letter: 'M',
    word: 'match',
    audioPath: 'match.mp3',
    imagePath: 'match.png',
  ),
  AlphabetObject(
    id: 3,
    letter: 'L',
    word: 'lock',
    audioPath: 'lock.mp3',
    imagePath: 'lock.png',
  ),
];

const _config = LetterLearningConfig(
  targetCellSize: 48,
  sourceCellSize: 48,
  winningScore: 10,
  promptGap: Duration.zero,
  successFeedbackDuration: Duration.zero,
);

LetterLearningController _controller(_FakeAudioPlayer audio) =>
    LetterLearningController(
      audio,
      alphabet: _alphabet,
      objects: _objects,
      config: _config,
      random: Random(1),
    );

void main() {
  test('starts masked and prompts with letter then object word', () async {
    final audio = _FakeAudioPlayer();
    final controller = _controller(audio);

    expect(controller.mode, LetterLearningMode.masked);
    expect(controller.isTargetRevealed, isFalse);
    expect(controller.sourceLetters.map((item) => item.letter), ['A', 'M']);
    expect(controller.slots.where((slot) => slot.isTarget), hasLength(1));

    await controller.playPrompt();
    expect(audio.playedPaths, [
      controller.currentLetter.audioPath,
      controller.currentObject.audioPath,
    ]);
  });

  test('mode changes reveal the same exercise immediately', () {
    final controller = _controller(_FakeAudioPlayer());
    final object = controller.currentObject;

    controller.setMode(LetterLearningMode.unmasked);

    expect(controller.currentObject, same(object));
    expect(controller.isTargetRevealed, isTrue);
  });

  test('tap-tap selection toggles and wrong guesses keep selection', () async {
    final controller = _controller(_FakeAudioPlayer());
    final correct = controller.currentLetter.letter;
    final wrong = correct == 'A' ? 'M' : 'A';

    controller.selectLetter(wrong);
    await controller.guessSelected();
    expect(controller.selectedLetter, wrong);

    controller.selectLetter(wrong);
    expect(controller.selectedLetter, isNull);
    controller.selectLetter(correct);
    await controller.guessSelected();
    expect(controller.selectedLetter, isNull);
    expect(controller.score, 1);
  });

  test(
    'wrong guesses do not score and correct guesses reveal and score',
    () async {
      final audio = _FakeAudioPlayer();
      final controller = _controller(audio);
      final wrong = controller.currentLetter.letter == 'A' ? 'M' : 'A';

      await controller.guess(wrong);
      expect(controller.score, 0);
      expect(audio.playedPaths.last, 'assets/audio/letter_dragging/pop.wav');

      final correct = controller.currentLetter.letter;
      await controller.guess(correct);
      expect(controller.score, 1);
      expect(controller.state, LetterLearningState.playing);
    },
  );

  test('difficulty changes reset exercise but preserve rewards', () async {
    final controller = _controller(_FakeAudioPlayer());
    await controller.guess(controller.currentLetter.letter);

    controller.setTiers({2});

    expect(controller.score, 1);
    expect(controller.currentLetter.letter, 'L');
    expect(controller.sourceLetters.map((item) => item.letter), ['L']);
  });

  test('ten correct answers end the activity', () async {
    final controller = _controller(_FakeAudioPlayer());

    for (var index = 0; index < 10; index++) {
      await controller.guess(controller.currentLetter.letter);
    }

    expect(controller.score, 10);
    expect(controller.state, LetterLearningState.won);
    expect(controller.isTargetRevealed, isTrue);
  });
}
