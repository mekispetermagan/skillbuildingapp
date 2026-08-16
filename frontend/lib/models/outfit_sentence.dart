enum SentencePerson {
  mary('Mary'),
  sarah('Sarah'),
  timothy('Timothy');

  final String displayName;

  const SentencePerson(this.displayName);
}

enum GarmentColor { blue, green, red, yellow }

enum ClothingPiece { shirt, jeans }

class OutfitSentence {
  final SentencePerson person;
  final GarmentColor color;
  final ClothingPiece piece;

  const OutfitSentence({
    required this.person,
    required this.color,
    required this.piece,
  });

  String get text => switch (piece) {
    ClothingPiece.shirt =>
      '${person.displayName} is wearing a ${color.name} shirt.',
    ClothingPiece.jeans =>
      '${person.displayName} is wearing ${color.name} jeans.',
  };

  String get imagePath =>
      'assets/images/sentence_building/'
      '${person.name}_${piece.name}_${color.name}.svg';

  @override
  bool operator ==(Object other) =>
      other is OutfitSentence &&
      other.person == person &&
      other.color == color &&
      other.piece == piece;

  @override
  int get hashCode => Object.hash(person, color, piece);
}
