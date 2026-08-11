class MemoryPair {
  final int id;
  final String word;
  final String imagePath;

  const MemoryPair({
    required this.id,
    required this.word,
    required this.imagePath,
  });

  factory MemoryPair.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final word = json['word'];
    final imagePath = json['image_path'];
    if (id is! int || word is! String || imagePath is! String) {
      throw const FormatException(
        'A memory pair needs an id, word, and image path.',
      );
    }
    return MemoryPair(id: id, word: word, imagePath: imagePath);
  }
}
