import 'outfit_sentence.dart';

class SentenceContent {
  final Map<SentencePerson, String> personNames;
  final Map<GarmentColor, String> colorNames;
  final Map<ClothingPiece, String> pieceNames;
  final String Function(String name, String color, String piece) sentence;

  const SentenceContent({
    required this.personNames,
    required this.colorNames,
    required this.pieceNames,
    required this.sentence,
  });

  String personName(SentencePerson person) => personNames[person]!;
  String colorName(GarmentColor color) => colorNames[color]!;
  String pieceName(ClothingPiece piece) => pieceNames[piece]!;

  String sentenceFor(OutfitSentence value) => sentence(
    personName(value.person),
    colorName(value.color),
    pieceName(value.piece),
  );

  String compose({
    SentencePerson? person,
    GarmentColor? color,
    ClothingPiece? piece,
  }) => sentence(
    person == null ? '…' : personName(person),
    color == null ? '…' : colorName(color),
    piece == null ? '…' : pieceName(piece),
  );
}

final englishSentenceContent = SentenceContent(
  personNames: const {
    SentencePerson.mary: 'Mary',
    SentencePerson.sarah: 'Sarah',
    SentencePerson.timothy: 'Timothy',
  },
  colorNames: const {
    GarmentColor.blue: 'blue',
    GarmentColor.green: 'green',
    GarmentColor.red: 'red',
    GarmentColor.yellow: 'yellow',
  },
  pieceNames: const {
    ClothingPiece.shirt: 'shirt',
    ClothingPiece.jeans: 'jeans',
  },
  sentence: (name, color, piece) => piece == 'shirt'
      ? '$name wears a $color $piece.'
      : '$name wears $color $piece.',
);

final hungarianSentenceContent = SentenceContent(
  personNames: const {
    SentencePerson.mary: 'Márti',
    SentencePerson.sarah: 'Sára',
    SentencePerson.timothy: 'Tamás',
  },
  colorNames: const {
    GarmentColor.blue: 'kék',
    GarmentColor.green: 'zöld',
    GarmentColor.red: 'piros',
    GarmentColor.yellow: 'sárga',
  },
  pieceNames: const {
    ClothingPiece.shirt: 'póló',
    ClothingPiece.jeans: 'nadrág',
  },
  sentence: (name, color, piece) => '$name $color ${piece}ban van.',
);
