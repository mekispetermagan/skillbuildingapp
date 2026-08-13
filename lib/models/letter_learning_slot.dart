class LetterLearningSlot {
  final int id;
  final String letter;
  final String? colorName;
  final bool isTarget;
  final bool isInSelectedGroups;

  const LetterLearningSlot({
    required this.id,
    required this.letter,
    required this.colorName,
    required this.isTarget,
    required this.isInSelectedGroups,
  });
}
