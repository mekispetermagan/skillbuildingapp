class CrosswordEntry {
  final String word;
  final String clue;

  const CrosswordEntry({required this.word, required this.clue});

  factory CrosswordEntry.fromJson(Map<String, dynamic> json) {
    final word = json['word'];
    final clue = json['clue'];
    if (word is! String || clue is! String) {
      throw const FormatException('A crossword entry needs a word and clue.');
    }
    final normalizedWord = word.trim().toUpperCase();
    final normalizedClue = clue.trim();
    if (!RegExp(r'^\p{L}{3,6}$', unicode: true).hasMatch(normalizedWord)) {
      throw FormatException('Invalid crossword word: $word');
    }
    if (normalizedClue.isEmpty) {
      throw const FormatException('A crossword clue must not be empty.');
    }
    return CrosswordEntry(word: normalizedWord, clue: normalizedClue);
  }
}
