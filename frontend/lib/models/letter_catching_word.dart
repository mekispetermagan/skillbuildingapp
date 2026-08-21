import 'bracketed_word.dart';

class LetterCatchingWord {
  final int id;
  final String word;
  final String imagePath;

  const LetterCatchingWord({
    required this.id,
    required this.word,
    this.imagePath = '',
  });

  List<String> get letterTokens => tokenizeBracketedWord(word);

  factory LetterCatchingWord.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final word = json['word'];
    final imagePath = json['image_path'];
    if (id is! int || word is! String || imagePath is! String) {
      throw const FormatException(
        'A letter-catching word needs an id, word, and image path.',
      );
    }
    final normalized = word.trim().toUpperCase();
    final tokens = tokenizeBracketedWord(normalized);
    if (tokens.isEmpty) {
      throw FormatException('Word must not be empty: $word');
    }
    return LetterCatchingWord(
      id: id,
      word: normalized,
      imagePath: imagePath.trim(),
    );
  }
}
