import 'bracketed_word.dart';

class MissingLettersWord {
  final int id;
  final String word;
  final String imagePath;

  const MissingLettersWord({
    required this.id,
    required this.word,
    required this.imagePath,
  });

  List<String> get letterTokens => tokenizeBracketedWord(word);

  factory MissingLettersWord.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final word = json['word'];
    final imagePath = json['image_path'];
    if (id is! int || word is! String || imagePath is! String) {
      throw const FormatException(
        'A missing-letters word needs an id, word, and image path.',
      );
    }

    final normalized = word.trim().toUpperCase();
    if (tokenizeBracketedWord(normalized).length < 2) {
      throw FormatException('Word needs at least two letters: $word');
    }
    return MissingLettersWord(id: id, word: normalized, imagePath: imagePath);
  }
}
