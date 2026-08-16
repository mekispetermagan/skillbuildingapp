import 'layered_person_outfit.dart';
import 'outfit_sentence.dart';

class SentenceQuizQuestion {
  final LayeredPersonOutfit outfit;
  final List<OutfitSentence> options;
  final int correctIndex;

  SentenceQuizQuestion({
    required this.outfit,
    required List<OutfitSentence> options,
    required this.correctIndex,
  }) : options = List.unmodifiable(options) {
    RangeError.checkValidIndex(correctIndex, options, 'correctIndex');
  }

  OutfitSentence get solution => options[correctIndex];

  OutfitSentence get visibleShirt => outfit.visibleShirt;

  OutfitSentence get visibleJeans => outfit.visibleJeans;
}
