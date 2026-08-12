import 'answer_feedback.dart';
import 'alphabet_letter.dart';
import 'countdown_status.dart';
import 'conveyor_state.dart';
import 'conveyor_world.dart';
import 'crossword_config.dart';
import 'crossword_puzzle.dart';
import 'crossword_state.dart';
import 'image_word.dart';
import 'layered_person_outfit.dart';
import 'letter_catching_world.dart';
import 'letter_catching_state.dart';
import 'letter_dragging_state.dart';
import 'letter_dragging_tile.dart';
import 'letter_practice_config.dart';
import 'letter_practice_slot.dart';
import 'letter_practice_state.dart';
import 'letter_shooting_world.dart';
import 'letter_shooting_state.dart';
import 'memory_card_data.dart';
import 'memory_config.dart';
import 'missing_letter_slot.dart';
import 'missing_letter_tile.dart';
import 'missing_letters_state.dart';
import 'outfit_sentence.dart';
import 'phrase_building_state.dart';
import 'phrase_building_tile.dart';
import 'sentence_quiz_question.dart';
import 'sentence_composer_state.dart';
import 'sentence_quiz_state.dart';
import 'spelling_quiz_question.dart';
import 'spelling_quiz_state.dart';

class PhraseBuildingViewData {
  final bool isLoading;
  final String? errorMessage;
  final List<PhraseBuildingTile> sourcePool;
  final List<PhraseBuildingTile> targetPool;
  final PhraseBuildingState state;

  const PhraseBuildingViewData({
    required this.isLoading,
    required this.errorMessage,
    required this.sourcePool,
    required this.targetPool,
    required this.state,
  });
}

class LetterDraggingViewData {
  final bool isLoading;
  final String? errorMessage;
  final List<LetterDraggingTile> tiles;
  final LetterDraggingState state;
  final int score;
  final CountdownStatus? countdown;

  const LetterDraggingViewData({
    required this.isLoading,
    required this.errorMessage,
    required this.tiles,
    required this.state,
    required this.score,
    required this.countdown,
  });
}

class MissingLettersViewData {
  final bool isLoading;
  final String? errorMessage;
  final List<MissingLetterSlot> slots;
  final List<MissingLetterTile> pool;
  final MissingLettersState state;
  final int score;

  const MissingLettersViewData({
    required this.isLoading,
    required this.errorMessage,
    required this.slots,
    required this.pool,
    required this.state,
    required this.score,
  });
}

class MemoryViewData {
  final bool isLoading;
  final String? errorMessage;
  final List<MemoryCardData> cards;
  final bool isComplete;
  final MemoryConfig config;

  const MemoryViewData({
    required this.isLoading,
    required this.errorMessage,
    required this.cards,
    required this.isComplete,
    required this.config,
  });
}

class LetterShootingViewData {
  final bool isLoading;
  final String? errorMessage;
  final LetterShootingWorld? world;
  final LetterShootingState state;

  const LetterShootingViewData({
    required this.isLoading,
    required this.errorMessage,
    required this.world,
    required this.state,
  });
}

class LetterCatchingViewData {
  final bool isLoading;
  final String? errorMessage;
  final LetterCatchingWorld? world;
  final LetterCatchingState state;

  const LetterCatchingViewData({
    required this.isLoading,
    required this.errorMessage,
    required this.world,
    required this.state,
  });
}

class ConveyorViewData {
  final bool isLoading;
  final String? errorMessage;
  final ConveyorWorld? world;
  final ConveyorState state;

  const ConveyorViewData({
    required this.isLoading,
    required this.errorMessage,
    required this.world,
    required this.state,
  });
}

class SentenceQuizViewData {
  final SentenceQuizQuestion question;
  final SentenceQuizState state;
  final int score;
  final int? correctHighlightIndex;
  final int? wrongHighlightIndex;
  final bool canSubmit;

  const SentenceQuizViewData({
    required this.question,
    required this.state,
    required this.score,
    required this.correctHighlightIndex,
    required this.wrongHighlightIndex,
    required this.canSubmit,
  });
}

class SentenceComposerViewData {
  final LayeredPersonOutfit outfit;
  final SentencePerson? selectedPerson;
  final GarmentColor? selectedColor;
  final ClothingPiece? selectedPiece;
  final SentenceComposerState state;
  final int score;
  final String composedSentence;
  final bool canSelect;
  final bool canSubmit;
  final Map<SentencePerson, AnswerFeedback> personFeedback;
  final Map<GarmentColor, AnswerFeedback> colorFeedback;
  final Map<ClothingPiece, AnswerFeedback> pieceFeedback;

  const SentenceComposerViewData({
    required this.outfit,
    required this.selectedPerson,
    required this.selectedColor,
    required this.selectedPiece,
    required this.state,
    required this.score,
    required this.composedSentence,
    required this.canSelect,
    required this.canSubmit,
    required this.personFeedback,
    required this.colorFeedback,
    required this.pieceFeedback,
  });
}

class SpellingQuizViewData {
  final bool isLoading;
  final String? errorMessage;
  final SpellingQuizQuestion? question;
  final SpellingQuizState state;
  final int score;
  final int? correctHighlightIndex;
  final int? wrongHighlightIndex;
  final bool canSubmit;

  const SpellingQuizViewData({
    required this.isLoading,
    required this.errorMessage,
    required this.question,
    required this.state,
    required this.score,
    required this.correctHighlightIndex,
    required this.wrongHighlightIndex,
    required this.canSubmit,
  });
}

class CrosswordViewData {
  final bool isLoading;
  final String? errorMessage;
  final CrosswordPuzzle? puzzle;
  final CrosswordConfig config;
  final CrosswordState state;
  final int score;
  final String? selectedLetter;

  const CrosswordViewData({
    required this.isLoading,
    required this.errorMessage,
    required this.puzzle,
    required this.config,
    required this.state,
    required this.score,
    required this.selectedLetter,
  });
}

class LetterPracticeViewData {
  final bool isLoading;
  final String? errorMessage;
  final ImageWord? currentWord;
  final List<LetterPracticeSlot> slots;
  final List<AlphabetLetter> sourceLetters;
  final Set<AlphabetDifficulty> difficulties;
  final bool useColors;
  final String? selectedLetter;
  final int sourceColumnCount;
  final int score;
  final LetterPracticeState state;
  final LetterPracticeConfig config;
  final bool canPlay;

  const LetterPracticeViewData({
    required this.isLoading,
    required this.errorMessage,
    required this.currentWord,
    required this.slots,
    required this.sourceLetters,
    required this.difficulties,
    required this.useColors,
    required this.selectedLetter,
    required this.sourceColumnCount,
    required this.score,
    required this.state,
    required this.config,
    required this.canPlay,
  });
}
