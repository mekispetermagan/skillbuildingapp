import 'countdown_status.dart';
import 'conveyor_world.dart';
import 'layered_person_outfit.dart';
import 'letter_catching_world.dart';
import 'letter_dragging_state.dart';
import 'letter_dragging_tile.dart';
import 'letter_shooting_world.dart';
import 'memory_card_data.dart';
import 'missing_letter_slot.dart';
import 'missing_letter_tile.dart';
import 'missing_letters_state.dart';
import 'phrase_building_state.dart';
import 'phrase_building_tile.dart';
import 'sentence_quiz_question.dart';
import 'sentence_quiz_sentence.dart';

enum LetterShootingState { playing, ended }

enum LetterCatchingState { playing, won, lost }

enum ConveyorState { playing, won, lost }

enum SentenceQuizState { guessing, feedback, won }

enum SentenceComposerState { composing, feedback, won }

enum ComposerChoiceFeedback { neutral, correct, wrong }

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

  const MemoryViewData({
    required this.isLoading,
    required this.errorMessage,
    required this.cards,
    required this.isComplete,
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
  final Map<SentencePerson, ComposerChoiceFeedback> personFeedback;
  final Map<GarmentColor, ComposerChoiceFeedback> colorFeedback;
  final Map<ClothingPiece, ComposerChoiceFeedback> pieceFeedback;

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
