import 'learning_area.dart';

enum ActivityId {
  letterLearning('letter_learning'),
  letterPractice('letter_practice'),
  phraseBuilding('phrase_building'),
  letterDragging('letter_dragging'),
  missingLetters('missing_letters'),
  letterShooting('letter_shooting'),
  memoryCards('memory_cards'),
  letterCatching('letter_catching'),
  wordConveyor('word_conveyor'),
  sentenceQuiz('sentence_quiz'),
  sentenceComposer('sentence_composer'),
  spellingQuiz('spelling_quiz'),
  crossword('crossword'),
  numberLearning('number_learning'),
  numberComparison('number_comparison'),
  operationsPractice('operations_practice'),
  numberDragging('number_dragging'),
  operatorConveyor('operator_conveyor'),
  evenOdd('even_odd');

  final String wireName;

  const ActivityId(this.wireName);

  LearningArea get area => switch (this) {
    ActivityId.numberLearning ||
    ActivityId.numberComparison ||
    ActivityId.operationsPractice ||
    ActivityId.numberDragging ||
    ActivityId.operatorConveyor ||
    ActivityId.evenOdd => LearningArea.math,
    _ => LearningArea.literacy,
  };

  static ActivityId fromWireName({
    required LearningArea area,
    required String value,
  }) {
    return values
        .where((activity) => activity.area == area)
        .firstWhere(
          (activity) => activity.wireName == value,
          orElse: () => throw FormatException('Unknown feature: $value'),
        );
  }
}
