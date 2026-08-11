class ConveyorWord {
  final int id;
  final String word;
  final String imagePath;

  const ConveyorWord({
    required this.id,
    required this.word,
    required this.imagePath,
  });

  factory ConveyorWord.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final word = json['word'];
    final imagePath = json['image_path'];
    if (id is! int || word is! String || imagePath is! String) {
      throw const FormatException(
        'A conveyor word needs an id, word, and image path.',
      );
    }
    final normalized = word.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]+(?: [A-Z]+)*$').hasMatch(normalized)) {
      throw FormatException('Invalid conveyor word: $word');
    }
    if (normalized.replaceAll(' ', '').length < 2) {
      throw FormatException('Conveyor words need at least two letters: $word');
    }
    return ConveyorWord(id: id, word: normalized, imagePath: imagePath);
  }
}
