enum AlphabetDifficulty { beginner, intermediate, advanced }

class AlphabetLetter {
  final int id;
  final String letter;
  final String colorName;
  final AlphabetDifficulty difficulty;

  const AlphabetLetter({
    required this.id,
    required this.letter,
    required this.colorName,
    required this.difficulty,
  });

  factory AlphabetLetter.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final letter = json['letter'];
    final color = json['color'];
    final difficultyName = json['difficulty'];
    if (id is! int ||
        letter is! String ||
        color is! String ||
        difficultyName is! String) {
      throw const FormatException(
        'An alphabet letter needs an id, letter, color, and difficulty.',
      );
    }
    final normalizedLetter = letter.trim().toUpperCase();
    final normalizedColor = color.trim();
    final difficulty = AlphabetDifficulty.values
        .where((value) => value.name == difficultyName.trim())
        .firstOrNull;
    if (!RegExp(r'^[A-Z]$').hasMatch(normalizedLetter) ||
        normalizedColor.isEmpty ||
        difficulty == null) {
      throw FormatException('Invalid alphabet letter: $json');
    }
    return AlphabetLetter(
      id: id,
      letter: normalizedLetter,
      colorName: normalizedColor,
      difficulty: difficulty,
    );
  }
}
