class LetterShootingWord {
  final int id;
  final String word;

  const LetterShootingWord({required this.id, required this.word});

  factory LetterShootingWord.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final word = json['word'];
    if (id is! int || word is! String) {
      throw const FormatException(
        'A letter-shooting word needs an id and word.',
      );
    }

    final normalizedWord = word.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]+$').hasMatch(normalizedWord) ||
        !RegExp(r'[AEIOU]').hasMatch(normalizedWord)) {
      throw FormatException('Word needs letters and at least one vowel: $word');
    }
    return LetterShootingWord(id: id, word: normalizedWord);
  }
}
