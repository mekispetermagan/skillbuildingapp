class ImageWord {
  final int id;
  final String word;
  final String imagePath;
  final String audioPath;

  const ImageWord({
    required this.id,
    required this.word,
    required this.imagePath,
    required this.audioPath,
  });

  String get uppercaseWord => word.toUpperCase();

  factory ImageWord.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final word = json['word'];
    final imagePath = json['image_path'];
    final audioPath = json['audio_path'];
    if (id is! int ||
        word is! String ||
        imagePath is! String ||
        audioPath is! String) {
      throw const FormatException(
        'An image word needs an id, word, image path, and audio path.',
      );
    }
    final normalizedWord = word.trim().toLowerCase();
    final normalizedPath = imagePath.trim();
    final normalizedAudioPath = audioPath.trim();
    if (!RegExp(r'^[a-z]+(?: [a-z]+)*$').hasMatch(normalizedWord)) {
      throw FormatException('Invalid image word: $word');
    }
    if (normalizedPath.isEmpty) {
      throw const FormatException('An image word needs an image path.');
    }
    if (normalizedAudioPath.isEmpty) {
      throw const FormatException('An image word needs an audio path.');
    }
    return ImageWord(
      id: id,
      word: normalizedWord,
      imagePath: normalizedPath,
      audioPath: normalizedAudioPath,
    );
  }
}
