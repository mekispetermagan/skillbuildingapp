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
  crossword('crossword');

  final String wireName;

  const ActivityId(this.wireName);

  LearningArea get area => LearningArea.literacy;

  static ActivityId fromWireName({
    required LearningArea area,
    required String value,
  }) {
    if (area != LearningArea.literacy) {
      throw FormatException(
        'No activities are registered for ${area.wireName}.',
      );
    }
    return values.firstWhere(
      (activity) => activity.wireName == value,
      orElse: () => throw FormatException('Unknown feature: $value'),
    );
  }
}
