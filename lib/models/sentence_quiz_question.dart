import 'layered_person_outfit.dart';
import 'sentence_quiz_sentence.dart';

class SentenceQuizQuestion {
  final LayeredPersonOutfit outfit;
  final List<SentenceQuizSentence> options;
  final int correctIndex;

  SentenceQuizQuestion({
    required this.outfit,
    required List<SentenceQuizSentence> options,
    required this.correctIndex,
  }) : options = List.unmodifiable(options) {
    RangeError.checkValidIndex(correctIndex, options, 'correctIndex');
  }

  SentenceQuizSentence get solution => options[correctIndex];

  SentenceQuizSentence get visibleShirt => outfit.visibleShirt;

  SentenceQuizSentence get visibleJeans => outfit.visibleJeans;
}
