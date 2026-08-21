import 'bracketed_word.dart';

class LetterDraggingWord {
  final int id;
  final String word;
  final String imagePath;

  const LetterDraggingWord({
    required this.id,
    required this.word,
    required this.imagePath,
  });

  List<String> get letterTokens => tokenizeBracketedWord(word);

  factory LetterDraggingWord.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final word = json['word'];
    final imagePath = json['image_path'];
    if (id is! int || word is! String || imagePath is! String) {
      throw const FormatException(
        'A letter-dragging word needs an id, word, and image path.',
      );
    }

    final normalized = word.trim().toUpperCase();
    final letters = tokenizeBracketedWord(normalized);
    if (letters.length < 2 || letters.toSet().length < 2) {
      throw FormatException('Word cannot be shuffled: $word');
    }
    return LetterDraggingWord(id: id, word: normalized, imagePath: imagePath);
  }
}
