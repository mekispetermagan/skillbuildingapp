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

  List<String> get letterTokens {
    final tokens = <String>[];
    final characters = uppercaseWord.split('');
    for (var index = 0; index < characters.length; index++) {
      if (characters[index] != '[') {
        if (characters[index] == ']') {
          throw FormatException('Invalid bracketed letter in word: $word');
        }
        tokens.add(characters[index]);
        continue;
      }
      final closing = characters.indexOf(']', index + 1);
      if (closing < 0 ||
          closing == index + 1 ||
          characters.sublist(index + 1, closing).contains('[')) {
        throw FormatException('Invalid bracketed letter in word: $word');
      }
      tokens.add(characters.sublist(index + 1, closing).join());
      index = closing;
    }
    return List.unmodifiable(tokens);
  }

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
    if (!RegExp(r'^[a-záéíóöőúüű\[\] ]+$').hasMatch(normalizedWord)) {
      throw FormatException('Invalid image word: $word');
    }
    try {
      ImageWord(
        id: id,
        word: normalizedWord,
        imagePath: normalizedPath,
        audioPath: normalizedAudioPath,
      ).letterTokens;
    } on FormatException {
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
