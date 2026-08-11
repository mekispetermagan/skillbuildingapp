import 'dart:math';

import 'sentence_quiz_sentence.dart';

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

  SentenceQuizSentence get visibleShirt => SentenceQuizSentence(
    person: person,
    color: shirtColor,
    piece: ClothingPiece.shirt,
  );

  SentenceQuizSentence get visibleJeans => SentenceQuizSentence(
    person: person,
    color: jeansColor,
    piece: ClothingPiece.jeans,
  );

  GarmentColor colorFor(ClothingPiece piece) => switch (piece) {
    ClothingPiece.shirt => shirtColor,
    ClothingPiece.jeans => jeansColor,
  };
}
