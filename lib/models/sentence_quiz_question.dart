import 'sentence_quiz_sentence.dart';

class SentenceQuizQuestion {
  final SentencePerson person;
  final GarmentColor shirtColor;
  final GarmentColor jeansColor;
  final List<SentenceQuizSentence> options;
  final int correctIndex;

  SentenceQuizQuestion({
    required this.person,
    required this.shirtColor,
    required this.jeansColor,
    required List<SentenceQuizSentence> options,
    required this.correctIndex,
  }) : options = List.unmodifiable(options) {
    RangeError.checkValidIndex(correctIndex, options, 'correctIndex');
  }

  SentenceQuizSentence get solution => options[correctIndex];

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
}
