class ImageWord {
  final int id;
  final String word;
  final String imagePath;

  const ImageWord({
    required this.id,
    required this.word,
    required this.imagePath,
  });

  String get uppercaseWord => word.toUpperCase();

  factory ImageWord.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final word = json['word'];
    final imagePath = json['image_path'];
    if (id is! int || word is! String || imagePath is! String) {
      throw const FormatException(
        'An image word needs an id, word, and image path.',
      );
    }
    final normalizedWord = word.trim().toLowerCase();
    final normalizedPath = imagePath.trim();
    if (!RegExp(r'^[a-z]+(?: [a-z]+)*$').hasMatch(normalizedWord)) {
      throw FormatException('Invalid image word: $word');
    }
    if (normalizedPath.isEmpty) {
      throw const FormatException('An image word needs an image path.');
    }
    return ImageWord(id: id, word: normalizedWord, imagePath: normalizedPath);
  }
}
