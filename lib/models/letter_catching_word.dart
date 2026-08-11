class LetterCatchingWord {
  final int id;
  final String word;

  const LetterCatchingWord({required this.id, required this.word});

  factory LetterCatchingWord.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final word = json['word'];
    if (id is! int || word is! String) {
      throw const FormatException(
        'A letter-catching word needs an id and word.',
      );
    }
    final normalized = word.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{4,7}$').hasMatch(normalized)) {
      throw FormatException('Word needs four to seven letters: $word');
    }
    return LetterCatchingWord(id: id, word: normalized);
  }
}
