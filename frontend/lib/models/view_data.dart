import 'answer_feedback.dart';
import 'alphabet_letter.dart';
import 'alphabet_object.dart';
import 'balance_game.dart';
import 'countdown_status.dart';
import 'conveyor_state.dart';
import 'conveyor_config.dart';
import 'conveyor_world.dart';
import 'crossword_config.dart';
import 'crossword_puzzle.dart';
import 'crossword_state.dart';
import 'feature_load_error.dart';
import 'even_odd_world.dart';
import 'image_word.dart';
import 'layered_person_outfit.dart';
import 'letter_catching_world.dart';
import 'letter_catching_state.dart';
import 'letter_dragging_state.dart';
import 'letter_dragging_tile.dart';
import 'letter_learning_config.dart';
import 'letter_learning_slot.dart';
import 'letter_learning_state.dart';
import 'letter_practice_config.dart';
import 'letter_practice_slot.dart';
import 'letter_practice_state.dart';
import 'letter_practice_word_set.dart';
import 'letter_shooting_world.dart';
import 'letter_shooting_state.dart';
import 'logic_game.dart';
import 'memory_card_data.dart';
import 'memory_config.dart';
import 'missing_letter_slot.dart';
import 'missing_letter_tile.dart';
import 'missing_letters_state.dart';
import 'number_learning.dart';
import 'number_memory.dart';
import 'operations_practice.dart';
import 'number_comparison.dart';
import 'number_dragging.dart';
import 'outfit_sentence.dart';
import 'operator_conveyor_world.dart';
import 'phrase_building_state.dart';
import 'phrase_building_tile.dart';
import 'sentence_quiz_question.dart';
import 'sentence_composer_state.dart';
import 'sentence_quiz_state.dart';
import 'shopping_game.dart';
import 'spelling_quiz_question.dart';
import 'spelling_quiz_state.dart';

class PhraseBuildingViewData {
  final bool isLoading;
  final FeatureLoadError? loadError;
  final List<PhraseBuildingTile> sourcePool;
  final List<PhraseBuildingTile> targetPool;
  final PhraseBuildingState state;
  final int score;

  const PhraseBuildingViewData({
    required this.isLoading,
    required this.loadError,
    required this.sourcePool,
    required this.targetPool,
    required this.state,
    required this.score,
  });
}

class LetterDraggingViewData {
  final bool isLoading;
  final FeatureLoadError? loadError;
  final List<LetterDraggingTile> tiles;
  final LetterDraggingState state;
  final int score;
  final CountdownStatus? countdown;
  final String? imagePath;
  final bool showImages;

  const LetterDraggingViewData({
    required this.isLoading,
    required this.loadError,
    required this.tiles,
    required this.state,
    required this.score,
    required this.countdown,
    required this.imagePath,
    required this.showImages,
  });
}

class MissingLettersViewData {
  final bool isLoading;
  final FeatureLoadError? loadError;
  final List<MissingLetterSlot> slots;
  final List<MissingLetterTile> pool;
  final MissingLettersState state;
  final int score;
  final int? selectedTileId;
  final String? imagePath;
  final bool showImages;

  const MissingLettersViewData({
    required this.isLoading,
    required this.loadError,
    required this.slots,
    required this.pool,
    required this.state,
    required this.score,
    required this.selectedTileId,
    required this.imagePath,
    required this.showImages,
  });
}

class MemoryViewData {
  final bool isLoading;
  final FeatureLoadError? loadError;
  final List<MemoryCardData> cards;
  final bool isComplete;
  final MemoryConfig config;

  const MemoryViewData({
    required this.isLoading,
    required this.loadError,
    required this.cards,
    required this.isComplete,
    required this.config,
  });
}

class NumberMemoryViewData {
  final List<NumberMemoryCardData> cards;
  final NumberMemoryRange range;
  final bool isComplete;
  final MemoryConfig config;

  const NumberMemoryViewData({
    required this.cards,
    required this.range,
    required this.isComplete,
    required this.config,
  });
}

class LetterShootingViewData {
  final bool isLoading;
  final FeatureLoadError? loadError;
  final LetterShootingWorld? world;
  final LetterShootingState state;

  const LetterShootingViewData({
    required this.isLoading,
    required this.loadError,
    required this.world,
    required this.state,
  });
}

class LetterCatchingViewData {
  final bool isLoading;
  final FeatureLoadError? loadError;
  final LetterCatchingWorld? world;
  final LetterCatchingState state;

  const LetterCatchingViewData({
    required this.isLoading,
    required this.loadError,
    required this.world,
    required this.state,
  });
}

class EvenOddViewData {
  final EvenOddWorld world;
  final LetterCatchingState state;

  const EvenOddViewData({required this.world, required this.state});
}

class ConveyorViewData {
  final bool isLoading;
  final FeatureLoadError? loadError;
  final ConveyorWorld? world;
  final ConveyorState state;
  final int? selectedLetterId;
  final ConveyorDifficulty difficulty;

  const ConveyorViewData({
    required this.isLoading,
    required this.loadError,
    required this.world,
    required this.state,
    required this.selectedLetterId,
    required this.difficulty,
  });
}

class OperatorConveyorViewData {
  final OperatorConveyorWorld world;
  final ConveyorState state;
  final int? selectedOperatorId;
  final ConveyorDifficulty difficulty;

  const OperatorConveyorViewData({
    required this.world,
    required this.state,
    required this.selectedOperatorId,
    required this.difficulty,
  });
}

class SentenceQuizViewData {
  final SentenceQuizQuestion question;
  final List<String> optionTexts;
  final SentenceQuizState state;
  final int score;
  final int? correctHighlightIndex;
  final int? wrongHighlightIndex;
  final bool canSubmit;

  const SentenceQuizViewData({
    required this.question,
    required this.optionTexts,
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
  final Map<SentencePerson, String> personLabels;
  final Map<GarmentColor, String> colorLabels;
  final Map<ClothingPiece, String> pieceLabels;
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
    required this.personLabels,
    required this.colorLabels,
    required this.pieceLabels,
    required this.canSelect,
    required this.canSubmit,
    required this.personFeedback,
    required this.colorFeedback,
    required this.pieceFeedback,
  });
}

class SpellingQuizViewData {
  final bool isLoading;
  final FeatureLoadError? loadError;
  final SpellingQuizQuestion? question;
  final SpellingQuizState state;
  final int score;
  final int? correctHighlightIndex;
  final int? wrongHighlightIndex;
  final bool canSubmit;

  const SpellingQuizViewData({
    required this.isLoading,
    required this.loadError,
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
  final FeatureLoadError? loadError;
  final CrosswordPuzzle? puzzle;
  final CrosswordConfig config;
  final CrosswordState state;
  final int score;
  final String? selectedLetter;

  const CrosswordViewData({
    required this.isLoading,
    required this.loadError,
    required this.puzzle,
    required this.config,
    required this.state,
    required this.score,
    required this.selectedLetter,
  });
}

class LetterPracticeViewData {
  final bool isLoading;
  final FeatureLoadError? loadError;
  final ImageWord? currentWord;
  final List<LetterPracticeSlot> slots;
  final List<AlphabetLetter> sourceLetters;
  final List<int> availableTiers;
  final Set<int> tiers;
  final LetterPracticeWordSet wordSet;
  final bool useColors;
  final String? selectedLetter;
  final int sourceColumnCount;
  final int score;
  final LetterPracticeState state;
  final LetterPracticeConfig config;
  final bool canPlay;

  const LetterPracticeViewData({
    required this.isLoading,
    required this.loadError,
    required this.currentWord,
    required this.slots,
    required this.sourceLetters,
    required this.availableTiers,
    required this.tiers,
    required this.wordSet,
    required this.useColors,
    required this.selectedLetter,
    required this.sourceColumnCount,
    required this.score,
    required this.state,
    required this.config,
    required this.canPlay,
  });
}

class LetterLearningViewData {
  final bool isLoading;
  final FeatureLoadError? loadError;
  final AlphabetLetter? currentLetter;
  final AlphabetObject? currentObject;
  final List<LetterLearningSlot> slots;
  final List<AlphabetLetter> sourceLetters;
  final List<int> availableTiers;
  final Set<int> tiers;
  final LetterLearningMode mode;
  final LetterLearningState state;
  final int score;
  final int sourceColumnCount;
  final LetterLearningConfig config;
  final bool canGuess;
  final bool isTargetRevealed;
  final String? selectedLetter;

  const LetterLearningViewData({
    required this.isLoading,
    required this.loadError,
    required this.currentLetter,
    required this.currentObject,
    required this.slots,
    required this.sourceLetters,
    required this.availableTiers,
    required this.tiers,
    required this.mode,
    required this.state,
    required this.score,
    required this.sourceColumnCount,
    required this.config,
    required this.canGuess,
    required this.isTargetRevealed,
    required this.selectedLetter,
  });
}

class NumberLearningViewData {
  final NumberRange range;
  final bool useColors;
  final NumberLearningState state;
  final int score;
  final int target;
  final String emoji;
  final List<int> choices;
  final bool canGuess;
  final NumberLearningConfig config;

  const NumberLearningViewData({
    required this.range,
    required this.useColors,
    required this.state,
    required this.score,
    required this.target,
    required this.emoji,
    required this.choices,
    required this.canGuess,
    required this.config,
  });
}

class NumberComparisonViewData {
  final ComparisonRange range;
  final NumberArrangement arrangement;
  final NumberComparisonState state;
  final int score;
  final int leftNumber;
  final int rightNumber;
  final String leftEmoji;
  final String rightEmoji;
  final List<(double, double)> leftPositions;
  final List<(double, double)> rightPositions;
  final bool canGuess;
  final NumberComparisonConfig config;

  const NumberComparisonViewData({
    required this.range,
    required this.arrangement,
    required this.state,
    required this.score,
    required this.leftNumber,
    required this.rightNumber,
    required this.leftEmoji,
    required this.rightEmoji,
    required this.leftPositions,
    required this.rightPositions,
    required this.canGuess,
    required this.config,
  });
}

class BalanceGameViewData {
  final BalanceGameState state;
  final int score;
  final int incorrectAttempts;
  final int exerciseId;
  final List<int> goodsWeights;
  final List<BalanceStone> shelfStones;
  final List<BalanceStone> selectedStones;
  final bool canSelect;
  final double leftTrayY;
  final double rightTrayY;
  final double handAngle;
  final BalanceGameConfig config;

  const BalanceGameViewData({
    required this.state,
    required this.score,
    required this.incorrectAttempts,
    required this.exerciseId,
    required this.goodsWeights,
    required this.shelfStones,
    required this.selectedStones,
    required this.canSelect,
    required this.leftTrayY,
    required this.rightTrayY,
    required this.handAngle,
    required this.config,
  });
}

class LogicGameViewData {
  final LogicDifficulty difficulty;
  final LogicGameState state;
  final int score;
  final int incorrectAttempts;
  final List<LogicObject> objects;
  final List<LogicProperty> properties;
  final List<LogicPlacement> placements;
  final bool canPlace;
  final LogicGameConfig config;

  const LogicGameViewData({
    required this.difficulty,
    required this.state,
    required this.score,
    required this.incorrectAttempts,
    required this.objects,
    required this.properties,
    required this.placements,
    required this.canPlace,
    required this.config,
  });
}

class ShoppingGameViewData {
  final ShoppingGameState state;
  final int score;
  final int incorrectAttempts;
  final CashRegisterState cashRegisterState;
  final List<ShoppingGood> displayedGoods;
  final ShoppingPayment payment;
  final PaymentIntroState paymentIntroState;
  final bool canAnswerPayment;
  final List<ShoppingBalanceNote> balanceNotes;
  final int balance;
  final ShoppingGameConfig config;

  const ShoppingGameViewData({
    required this.state,
    required this.score,
    required this.incorrectAttempts,
    required this.cashRegisterState,
    required this.displayedGoods,
    required this.payment,
    required this.paymentIntroState,
    required this.canAnswerPayment,
    required this.balanceNotes,
    required this.balance,
    required this.config,
  });
}

class OperationsPracticeViewData {
  final Set<ElementaryOperator> operators;
  final OperationsRange range;
  final bool useColors;
  final OperationsPracticeState state;
  final int score;
  final ElementaryEquation equation;
  final List<int> choices;
  final bool canGuess;
  final OperationsPracticeConfig config;

  const OperationsPracticeViewData({
    required this.operators,
    required this.range,
    required this.useColors,
    required this.state,
    required this.score,
    required this.equation,
    required this.choices,
    required this.canGuess,
    required this.config,
  });
}

class NumberDraggingViewData {
  final List<NumberDraggingTile> tiles;
  final NumberDraggingRange range;
  final LetterDraggingState state;
  final int score;
  final CountdownStatus countdown;

  const NumberDraggingViewData({
    required this.tiles,
    required this.range,
    required this.state,
    required this.score,
    required this.countdown,
  });
}
