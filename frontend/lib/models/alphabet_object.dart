class AlphabetObject {
  final int id;
  final String letter;
  final String word;
  final String audioPath;
  final String imagePath;

  const AlphabetObject({
    required this.id,
    required this.letter,
    required this.word,
    required this.audioPath,
    required this.imagePath,
  });

  List<String> get letterTokens {
    final tokens = <String>[];
    final characters = word.toUpperCase().split('');
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

  factory AlphabetObject.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final letter = json['letter'];
    final word = json['word'];
    final audioPath = json['audio_path'];
    final imagePath = json['image_path'];
    if (id is! int ||
        letter is! String ||
        word is! String ||
        audioPath is! String ||
        imagePath is! String) {
      throw const FormatException(
        'An alphabet object needs an id, letter, word, audio path, and image path.',
      );
    }
    final normalizedLetter = letter.trim().toUpperCase();
    final normalizedWord = word.trim().toLowerCase();
    final normalizedAudioPath = audioPath.trim();
    final normalizedImagePath = imagePath.trim();
    if (!RegExp(r'^[A-Z]$').hasMatch(normalizedLetter) ||
        !RegExp(r'^[a-z]+$').hasMatch(normalizedWord) ||
        normalizedAudioPath.isEmpty ||
        normalizedImagePath.isEmpty) {
      throw FormatException('Invalid alphabet object: $json');
    }
    return AlphabetObject(
      id: id,
      letter: normalizedLetter,
      word: normalizedWord,
      audioPath: normalizedAudioPath,
      imagePath: normalizedImagePath,
    );
  }
}
