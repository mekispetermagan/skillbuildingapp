import 'image_word.dart';

class SpellingQuizQuestion {
  final ImageWord animal;
  final List<String> options;
  final int correctIndex;

  SpellingQuizQuestion({
    required this.animal,
    required List<String> options,
    required this.correctIndex,
  }) : options = List.unmodifiable(options) {
    RangeError.checkValidIndex(correctIndex, options, 'correctIndex');
  }

  String get solution => options[correctIndex];
}
