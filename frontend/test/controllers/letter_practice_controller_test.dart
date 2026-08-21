import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/audio/asset_audio_player.dart';
import 'package:skillbuilding_game/controllers/letter_practice_controller.dart';
import 'package:skillbuilding_game/models/alphabet_letter.dart';
import 'package:skillbuilding_game/models/image_word.dart';
import 'package:skillbuilding_game/models/letter_practice_config.dart';
import 'package:skillbuilding_game/models/letter_practice_state.dart';

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
    audioPath: 'audio/letter.mp3',
  ),
  AlphabetLetter(
    id: 2,
    letter: 'M',
    colorName: 'orange',
    tier: 1,
    audioPath: 'audio/letter.mp3',
  ),
  AlphabetLetter(
    id: 3,
    letter: 'S',
    colorName: 'amber',
    tier: 1,
    audioPath: 'audio/letter.mp3',
  ),
  AlphabetLetter(
    id: 4,
    letter: 'T',
    colorName: 'green',
    tier: 1,
    audioPath: 'audio/letter.mp3',
  ),
  AlphabetLetter(
    id: 5,
    letter: 'P',
    colorName: 'teal',
    tier: 1,
    audioPath: 'audio/letter.mp3',
  ),
  AlphabetLetter(
    id: 6,
    letter: 'F',
    colorName: 'blue',
    tier: 1,
    audioPath: 'audio/letter.mp3',
  ),
  AlphabetLetter(
    id: 7,
    letter: 'I',
    colorName: 'deepPurple',
    tier: 1,
    audioPath: 'audio/letter.mp3',
  ),
  AlphabetLetter(
    id: 8,
    letter: 'N',
    colorName: 'pink',
    tier: 1,
    audioPath: 'audio/letter.mp3',
  ),
  AlphabetLetter(
    id: 9,
    letter: 'O',
    colorName: 'brown',
    tier: 1,
    audioPath: 'audio/letter.mp3',
  ),
  AlphabetLetter(
    id: 10,
    letter: 'D',
    colorName: 'red',
    tier: 2,
    audioPath: 'audio/letter.mp3',
  ),
  AlphabetLetter(
    id: 11,
    letter: 'E',
    colorName: 'green',
    tier: 2,
    audioPath: 'audio/letter.mp3',
  ),
  AlphabetLetter(
    id: 12,
    letter: 'H',
    colorName: 'teal',
    tier: 2,
    audioPath: 'audio/letter.mp3',
  ),
  AlphabetLetter(
    id: 13,
    letter: 'C',
    colorName: 'red',
    tier: 3,
    audioPath: 'audio/letter.mp3',
  ),
  AlphabetLetter(
    id: 14,
    letter: 'G',
    colorName: 'orange',
    tier: 3,
    audioPath: 'audio/letter.mp3',
  ),
];

const _cat = ImageWord(
  id: 1,
  word: 'cat',
  imagePath: 'cat.png',
  audioPath: 'cat.mp3',
);
const _sheep = ImageWord(
  id: 2,
  word: 'sheep',
  imagePath: 'sheep.png',
  audioPath: 'sheep.mp3',
);
const _words = [_cat, _sheep];

const _config = LetterPracticeConfig(
  targetCellSize: 48,
  sourceCellSize: 48,
  winningScore: 10,
  completionFeedbackDuration: Duration.zero,
);

void main() {
  test('starts with beginner letters and masks only active groups', () {
    final controller = LetterPracticeController(
      _FakeAudioPlayer(),
      words: const [_cat],
      alphabet: _alphabet,
      config: _config,
      random: Random(1),
    );

    expect(controller.tiers, {1});
    expect(controller.sourceLetters, hasLength(9));
    expect(controller.sourceLetters.map((item) => item.letter), [
      'A',
      'F',
      'I',
      'M',
      'N',
      'O',
      'P',
      'S',
      'T',
    ]);
    expect(controller.sourceColumnCount, 5);
    expect(
      controller.slots
          .where((slot) => slot.isTarget)
          .map((slot) => slot.letter),
      ['A', 'T'],
    );
    expect(
      controller.slots.singleWhere((slot) => slot.letter == 'C').isRevealed,
      isTrue,
    );
    controller.dispose();
  });

  test('multi-selection unions groups and uses 5, 6, or 7 columns', () {
    final controller = LetterPracticeController(
      _FakeAudioPlayer(),
      words: _words,
      alphabet: _alphabet,
      config: _config,
      random: Random(2),
    );

    controller.setTiers({1, 2});
    expect(controller.sourceColumnCount, 6);
    expect(controller.sourceLetters, hasLength(12));
    expect(controller.sourceLetters.map((item) => item.letter), [
      'A',
      'D',
      'E',
      'F',
      'H',
      'I',
      'M',
      'N',
      'O',
      'P',
      'S',
      'T',
    ]);

    controller.setTiers({1, 2, 3});
    expect(controller.sourceColumnCount, 7);
    expect(controller.sourceLetters, hasLength(14));
    expect(controller.sourceLetters.map((item) => item.letter), [
      'A',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'M',
      'N',
      'O',
      'P',
      'S',
      'T',
    ]);
    expect(
      controller.slots
          .where((slot) => !slot.isSpace)
          .every((slot) => slot.isTarget),
      isTrue,
    );
    controller.dispose();
  });

  test('color setting changes without replacing the exercise', () {
    final controller = LetterPracticeController(
      _FakeAudioPlayer(),
      words: _words,
      alphabet: _alphabet,
      config: _config,
      random: Random(3),
    );
    final word = controller.currentWord;
    final slots = controller.slots;

    controller.setUseColors(false);

    expect(controller.useColors, isFalse);
    expect(controller.currentWord, same(word));
    expect(controller.slots, slots);
    controller.dispose();
  });

  test(
    'wrong placement keeps selection and correct placement clears it',
    () async {
      final audio = _FakeAudioPlayer();
      final controller = LetterPracticeController(
        audio,
        words: const [_cat],
        alphabet: _alphabet,
        config: _config,
        random: Random(4),
      );
      final aSlot = controller.slots.singleWhere((slot) => slot.letter == 'A');

      controller.selectLetter('T');
      await controller.placeSelected(aSlot.id);
      expect(controller.selectedLetter, 'T');
      expect(audio.playedPaths.last, 'assets/audio/letter_dragging/pop.wav');

      controller.selectLetter('A');
      await controller.placeSelected(aSlot.id);
      expect(controller.selectedLetter, isNull);
      expect(controller.slots[aSlot.id].isFilled, isTrue);
      expect(
        audio.playedPaths.last,
        'assets/audio/letter_dragging/correct.mp3',
      );
      controller.dispose();
    },
  );

  test('repeated letters fill the leftmost matching occurrence', () async {
    final controller = LetterPracticeController(
      _FakeAudioPlayer(),
      words: const [_sheep],
      alphabet: _alphabet,
      config: _config,
      random: Random(5),
    );
    controller.setTiers({2});
    final eSlots = controller.slots
        .where((slot) => slot.letter == 'E')
        .toList();

    await controller.place(slotId: eSlots.last.id, letter: 'E');

    expect(controller.slots[eSlots.first.id].isFilled, isTrue);
    expect(controller.slots[eSlots.last.id].isFilled, isFalse);
    controller.dispose();
  });

  test(
    'difficulty change preserves rewards and autoplays the new word',
    () async {
      final audio = _FakeAudioPlayer();
      final controller = LetterPracticeController(
        audio,
        words: _words,
        alphabet: _alphabet,
        config: _config,
        random: Random(6),
      );
      await _completeCurrentWord(controller);
      expect(controller.score, 1);

      controller.setTiers({3});
      await Future<void>.delayed(Duration.zero);

      expect(controller.score, 1);
      expect(controller.tiers, {3});
      expect(audio.playedPaths.last, controller.currentWord.audioPath);
      controller.dispose();
    },
  );

  test('awards one reward per word and wins at ten', () async {
    final audio = _FakeAudioPlayer();
    final controller = LetterPracticeController(
      audio,
      words: const [_cat],
      alphabet: _alphabet,
      config: _config,
      random: Random(7),
    );

    for (var score = 1; score <= 10; score++) {
      await _completeCurrentWord(controller);
      expect(controller.score, score);
    }
    expect(controller.state, LetterPracticeState.won);
    expect(
      audio.playedPaths,
      contains('assets/audio/letter_dragging/fanfare.mp3'),
    );
    controller.dispose();
  });

  test('derives a long Hungarian consonant card from its base letter', () {
    const word = ImageWord(
      id: 3,
      word: 've[ssz]ő',
      imagePath: 'vesszo.png',
      audioPath: 'vesszo.mp3',
    );
    const alphabet = [
      AlphabetLetter(
        id: 1,
        letter: 'SZ',
        colorName: 'orange',
        tier: 3,
        audioPath: 'sz.mp3',
      ),
    ];
    final controller = LetterPracticeController(
      _FakeAudioPlayer(),
      words: const [word],
      alphabet: alphabet,
      config: _config,
    );

    controller.setTiers({3});

    expect(controller.sourceLetters.map((letter) => letter.letter), [
      'SSZ',
      'SZ',
    ]);
    expect(controller.slots.map((slot) => slot.letter), ['V', 'E', 'SSZ', 'Ő']);
    expect(
      controller.slots.singleWhere((slot) => slot.letter == 'SSZ').isTarget,
      isTrue,
    );
    controller.dispose();
  });
}

Future<void> _completeCurrentWord(LetterPracticeController controller) async {
  for (final slot in controller.slots.where((slot) => slot.isTarget).toList()) {
    if (!controller.slots[slot.id].isFilled) {
      await controller.place(slotId: slot.id, letter: slot.letter);
    }
  }
}
