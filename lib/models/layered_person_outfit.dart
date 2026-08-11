import 'dart:math';

import 'outfit_sentence.dart';

class LayeredPersonOutfit {
  final SentencePerson person;
  final GarmentColor shirtColor;
  final GarmentColor jeansColor;

  const LayeredPersonOutfit({
    required this.person,
    required this.shirtColor,
    required this.jeansColor,
  });

  factory LayeredPersonOutfit.random(Random random) => LayeredPersonOutfit(
    person: SentencePerson.values[random.nextInt(SentencePerson.values.length)],
    shirtColor: GarmentColor.values[random.nextInt(GarmentColor.values.length)],
    jeansColor: GarmentColor.values[random.nextInt(GarmentColor.values.length)],
  );

  OutfitSentence get visibleShirt => OutfitSentence(
    person: person,
    color: shirtColor,
    piece: ClothingPiece.shirt,
  );

  OutfitSentence get visibleJeans => OutfitSentence(
    person: person,
    color: jeansColor,
    piece: ClothingPiece.jeans,
  );

  GarmentColor colorFor(ClothingPiece piece) => switch (piece) {
    ClothingPiece.shirt => shirtColor,
    ClothingPiece.jeans => jeansColor,
  };
}
