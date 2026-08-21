class AlphabetLetter {
  final int id;
  final String letter;
  final String colorName;
  final int tier;
  final String audioPath;
  final String? objectWord;

  const AlphabetLetter({
    required this.id,
    required this.letter,
    required this.colorName,
    required this.tier,
    required this.audioPath,
    this.objectWord,
  });

  factory AlphabetLetter.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final letter = json['letter'];
    final color = json['color'];
    final tierValue = json['tier'];
    final difficultyName = json['difficulty'];
    final audioPath = json['audio_path'];
    final objectWord = json['object_word'];
    if (id is! int ||
        letter is! String ||
        color is! String ||
        tierValue is! int && difficultyName is! String ||
        audioPath is! String ||
        objectWord != null && objectWord is! String) {
      throw const FormatException(
        'An alphabet letter needs an id, letter, color, difficulty, and audio path.',
      );
    }
    final normalizedLetter = letter
        .trim()
        .replaceAll(RegExp(r'^\[|\]$'), '')
        .toUpperCase();
    final normalizedColor = color.trim();
    final normalizedAudioPath = audioPath.trim();
    final normalizedObjectWord = objectWord is String
        ? objectWord.trim().toLowerCase()
        : null;
    final tier = tierValue is int
        ? tierValue
        : const {
            'beginner': 1,
            'intermediate': 2,
            'advanced': 3,
          }[(difficultyName as String).trim()];
    if (!RegExp(r'^[A-ZÁÉÍÓÖŐÚÜŰ]+$').hasMatch(normalizedLetter) ||
        normalizedColor.isEmpty ||
        normalizedAudioPath.isEmpty ||
        normalizedObjectWord != null && normalizedObjectWord.isEmpty ||
        tier == null ||
        tier < 1) {
      throw FormatException('Invalid alphabet letter: $json');
    }
    return AlphabetLetter(
      id: id,
      letter: normalizedLetter,
      colorName: normalizedColor,
      tier: tier,
      audioPath: normalizedAudioPath,
      objectWord: normalizedObjectWord,
    );
  }

  AlphabetLetter withLetter({required int id, required String letter}) =>
      AlphabetLetter(
        id: id,
        letter: letter,
        colorName: colorName,
        tier: tier,
        audioPath: audioPath,
        objectWord: objectWord,
      );
}
