class LetterPracticeSlot {
  final int id;
  final String letter;
  final String? colorName;
  final bool isTarget;
  final bool isFilled;

  const LetterPracticeSlot({
    required this.id,
    required this.letter,
    required this.colorName,
    required this.isTarget,
    this.isFilled = false,
  });

  bool get isSpace => letter == ' ';
  bool get isRevealed => !isTarget || isFilled;

  LetterPracticeSlot fill() => LetterPracticeSlot(
    id: id,
    letter: letter,
    colorName: colorName,
    isTarget: isTarget,
    isFilled: true,
  );
}
