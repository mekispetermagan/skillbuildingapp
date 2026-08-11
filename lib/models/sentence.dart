class Sentence {
  final int id;
  final String string;
  final String audioPath;

  const Sentence({
    required this.id,
    required this.string,
    required this.audioPath,
  });

  factory Sentence.fromJson(Map<String, dynamic> json) => Sentence(
    id: json['id'] as int,
    string: json['string'] as String,
    audioPath: json['audio_path'] as String,
  );
}
