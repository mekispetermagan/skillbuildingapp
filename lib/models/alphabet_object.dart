class AlphabetObject {
  final int id;
  final String letter;
  final String word;
  final String audioPath;

  const AlphabetObject({
    required this.id,
    required this.letter,
    required this.word,
    required this.audioPath,
  });

  factory AlphabetObject.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final letter = json['letter'];
    final word = json['word'];
    final audioPath = json['audio_path'];
    if (id is! int ||
        letter is! String ||
        word is! String ||
        audioPath is! String) {
      throw const FormatException(
        'An alphabet object needs an id, letter, word, and audio path.',
      );
    }
    final normalizedLetter = letter.trim().toUpperCase();
    final normalizedWord = word.trim().toLowerCase();
    final normalizedAudioPath = audioPath.trim();
    if (!RegExp(r'^[A-Z]$').hasMatch(normalizedLetter) ||
        !RegExp(r'^[a-z]+$').hasMatch(normalizedWord) ||
        normalizedAudioPath.isEmpty) {
      throw FormatException('Invalid alphabet object: $json');
    }
    return AlphabetObject(
      id: id,
      letter: normalizedLetter,
      word: normalizedWord,
      audioPath: normalizedAudioPath,
    );
  }
}
