class Sentence {
  final int id;
  final String text;
  final String audioPath;

  const Sentence({
    required this.id,
    required this.text,
    required this.audioPath,
  });

  factory Sentence.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final text = json['string'];
    final audioPath = json['audio_path'];
    if (id is! int || text is! String || audioPath is! String) {
      throw const FormatException(
        'A sentence needs an id, text, and audio path.',
      );
    }
    final normalizedText = text.trim();
    final normalizedPath = audioPath.trim();
    if (normalizedText.isEmpty || normalizedPath.isEmpty) {
      throw const FormatException(
        'Sentence text and audio path cannot be empty.',
      );
    }
    return Sentence(id: id, text: normalizedText, audioPath: normalizedPath);
  }
}
