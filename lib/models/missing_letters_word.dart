import 'package:characters/characters.dart';

class MissingLettersWord {
  final int id;
  final String word;

  const MissingLettersWord({required this.id, required this.word});

  factory MissingLettersWord.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final word = json['word'];
    if (id is! int || word is! String) {
      throw const FormatException(
        'A missing-letters word needs an id and word.',
      );
    }

    final normalized = word.trim().toUpperCase();
    if (normalized.characters.length < 2) {
      throw FormatException('Word needs at least two letters: $word');
    }
    return MissingLettersWord(id: id, word: normalized);
  }
}
