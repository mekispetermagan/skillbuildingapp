enum AlphabetDifficulty { beginner, intermediate, advanced }

class AlphabetLetter {
  final int id;
  final String letter;
  final String colorName;
  final AlphabetDifficulty difficulty;
  final String audioPath;

  const AlphabetLetter({
    required this.id,
    required this.letter,
    required this.colorName,
    required this.difficulty,
    required this.audioPath,
  });

  factory AlphabetLetter.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final letter = json['letter'];
    final color = json['color'];
    final difficultyName = json['difficulty'];
    final audioPath = json['audio_path'];
    if (id is! int ||
        letter is! String ||
        color is! String ||
        difficultyName is! String ||
        audioPath is! String) {
      throw const FormatException(
        'An alphabet letter needs an id, letter, color, difficulty, and audio path.',
      );
    }
    final normalizedLetter = letter.trim().toUpperCase();
    final normalizedColor = color.trim();
    final normalizedAudioPath = audioPath.trim();
    final difficulty = AlphabetDifficulty.values
        .where((value) => value.name == difficultyName.trim())
        .firstOrNull;
    if (!RegExp(r'^[A-Z]$').hasMatch(normalizedLetter) ||
        normalizedColor.isEmpty ||
        normalizedAudioPath.isEmpty ||
        difficulty == null) {
      throw FormatException('Invalid alphabet letter: $json');
    }
    return AlphabetLetter(
      id: id,
      letter: normalizedLetter,
      colorName: normalizedColor,
      difficulty: difficulty,
      audioPath: normalizedAudioPath,
    );
  }
}
