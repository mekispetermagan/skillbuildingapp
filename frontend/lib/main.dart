import 'package:flutter/material.dart';

import 'api/gameplay_api_client.dart';
import 'config/gameplay_api_config.dart';
import 'controllers/session_controller.dart';
import 'l10n/l10n.dart';
import 'models/letter_dragging_state.dart';
import 'screens/screens.dart';
import 'services/gameplay_recorder.dart';
import 'storage/gameplay_record_store.dart';

void main() {
  final config = GameplayApiConfig.fromEnvironment();
  final recorder = SyncedGameplayRecorder(
    SharedPreferencesGameplayRecordStore(),
    GameplayApiClient(config: config),
  );
  runApp(LiteracyApp(gameplayRecorder: recorder));
}

class LiteracyApp extends StatelessWidget {
  final GameplayRecorder gameplayRecorder;

  const LiteracyApp({
    this.gameplayRecorder = const NoopGameplayRecorder(),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Temporary pre-pilot behavior: learning content is English-only, so
      // bypass language selection and pin the interface to English. For the
      // pilot, remove this explicit locale and restore LanguageSelectionScreen
      // as the gate before AppRoot (persisting the selected InterfaceLanguage).
      locale: const Locale('en'),
      onGenerateTitle: (context) => context.l10n.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          dynamicSchemeVariant: DynamicSchemeVariant.rainbow,
        ),
      ),
      home: AppRoot(gameplayRecorder: gameplayRecorder),
    );
  }
}

class AppRoot extends StatefulWidget {
  final GameplayRecorder gameplayRecorder;

  const AppRoot({
    this.gameplayRecorder = const NoopGameplayRecorder(),
    super.key,
  });

  @override
  State<AppRoot> createState() => AppRootState();
}

class AppRootState extends State<AppRoot> {
  late final SessionController _sessionController = SessionController(
    gameplayRecorder: widget.gameplayRecorder,
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _sessionController,
      builder: (_, _) => PopScope(
        canPop: _sessionController.status == SessionStatus.areaMenu,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _sessionController.status != SessionStatus.rating) {
            _sessionController.handleBack();
          }
        },
        child: switch (_sessionController.status) {
          SessionStatus.areaMenu => AreaMenuScreen(
            onOpenLiteracy: _sessionController.openLiteracyMenu,
            onOpenMath: _sessionController.openMathMenu,
          ),
          SessionStatus.literacyMenu => LiteracyMenuScreen(
            menuItems: _sessionController.literacyMenuItems,
            onBack: _sessionController.openAreaMenu,
          ),
          SessionStatus.mathMenu => MathMenuScreen(
            menuItems: _sessionController.mathMenuItems,
            onBack: _sessionController.openAreaMenu,
          ),
          SessionStatus.mathPlaceholder => MathPlaceholderScreen(
            featureNumber: _sessionController.mathPlaceholderNumber!,
            onBack: _sessionController.openMathMenu,
          ),
          SessionStatus.letterLearning => LetterLearningScreen(
            viewData: _sessionController.letterLearningViewData,
            onBack: _sessionController.openLiteracyMenu,
            onRestart: _sessionController.restartLetterLearning,
            onSetDifficulties: _sessionController.letterLearningSetDifficulties,
            onSetMode: _sessionController.letterLearningSetMode,
            onGuess: _sessionController.letterLearningGuess,
            onSelectLetter: _sessionController.letterLearningSelectLetter,
            onGuessSelected: _sessionController.letterLearningGuessSelected,
            onPlayAudio: _sessionController.letterLearningPlayAudio,
          ),
          SessionStatus.letterPractice => LetterPracticeScreen(
            viewData: _sessionController.letterPracticeViewData,
            onBack: _sessionController.openLiteracyMenu,
            onRestart: _sessionController.restartLetterPractice,
            onSetDifficulties: _sessionController.letterPracticeSetDifficulties,
            onSetUseColors: _sessionController.letterPracticeSetUseColors,
            onSelectLetter: _sessionController.letterPracticeSelectLetter,
            canPlace: _sessionController.letterPracticeCanPlace,
            onPlaceSelected: _sessionController.letterPracticePlaceSelected,
            onPlace: _sessionController.letterPracticePlace,
            onPlayAudio: _sessionController.letterPracticePlayAudio,
          ),
          SessionStatus.phraseBuilding => PhraseBuildingScreen(
            viewData: _sessionController.phraseBuildingViewData,
            onBack: _sessionController.openLiteracyMenu,
            onMove: _sessionController.phraseBuildingMove,
            canMoveToTarget: _sessionController.phraseBuildingCanMoveToTarget,
            canMoveToSource: _sessionController.phraseBuildingCanMoveToSource,
            onMoveToTarget: _sessionController.phraseBuildingMoveToTarget,
            onMoveToSource: _sessionController.phraseBuildingMoveToSource,
            onSubmit: _sessionController.phraseBuildingSubmit,
            onPlayAudio: _sessionController.phraseBuildingPlayAudio,
            onRestart: _sessionController.restartPhraseBuilding,
          ),
          SessionStatus.letterDragging =>
            _sessionController.letterDraggingViewData.state ==
                    LetterDraggingState.result
                ? LetterDraggingResultScreen(
                    score: _sessionController.letterDraggingViewData.score,
                    onBack: _sessionController.openLiteracyMenu,
                    onRestart: _sessionController.restartLetterDragging,
                  )
                : LetterDraggingScreen(
                    viewData: _sessionController.letterDraggingViewData,
                    onBack: _sessionController.openLiteracyMenu,
                    onReorder: _sessionController.letterDraggingReorder,
                    onPass: _sessionController.letterDraggingPass,
                    onShowImagesChanged:
                        _sessionController.letterDraggingSetShowImages,
                  ),
          SessionStatus.missingLetters => MissingLettersScreen(
            viewData: _sessionController.missingLettersViewData,
            onBack: _sessionController.openLiteracyMenu,
            canDrop: _sessionController.missingLettersCanDrop,
            onDrop: _sessionController.missingLettersDrop,
            onSelectTile: _sessionController.missingLettersSelectTile,
            onPlaceSelected: _sessionController.missingLettersPlaceSelected,
            onShowImagesChanged: _sessionController.missingLettersSetShowImages,
            onRestart: _sessionController.restartMissingLetters,
          ),
          SessionStatus.letterShooting => LetterShootingScreen(
            viewData: _sessionController.letterShootingViewData,
            onResize: _sessionController.letterShootingResize,
            onTick: _sessionController.letterShootingTick,
            onTap: _sessionController.letterShootingTap,
            onBeginAim: _sessionController.letterShootingBeginAim,
            onUpdateAim: _sessionController.letterShootingUpdateAim,
            onReleaseAim: _sessionController.letterShootingReleaseAim,
            onBack: _sessionController.openLiteracyMenu,
            onRestart: _sessionController.restartLetterShooting,
          ),
          SessionStatus.memory => MemoryScreen(
            viewData: _sessionController.memoryViewData,
            onBack: _sessionController.openLiteracyMenu,
            onSelect: _sessionController.memorySelect,
            onNewGame: _sessionController.memoryStartNewGame,
          ),
          SessionStatus.letterCatching => LetterCatchingScreen(
            viewData: _sessionController.letterCatchingViewData,
            onResize: _sessionController.letterCatchingResize,
            onTick: _sessionController.letterCatchingTick,
            onMovePaddleBy: _sessionController.letterCatchingMovePaddleBy,
            onBack: _sessionController.openLiteracyMenu,
            onRestart: _sessionController.restartLetterCatching,
          ),
          SessionStatus.conveyor => ConveyorScreen(
            viewData: _sessionController.conveyorViewData,
            onResize: _sessionController.conveyorResize,
            onTick: _sessionController.conveyorTick,
            canAccept: _sessionController.conveyorCanAccept,
            onStartDragging: _sessionController.conveyorStartDragging,
            onSelectLetter: _sessionController.conveyorSelectLetter,
            onPlaceSelected: _sessionController.conveyorPlaceSelected,
            onCancelDragging: _sessionController.conveyorCancelDragging,
            onDrop: _sessionController.conveyorDrop,
            onBack: _sessionController.openLiteracyMenu,
            onRestart: _sessionController.restartConveyor,
          ),
          SessionStatus.sentenceQuiz => SentenceQuizScreen(
            viewData: _sessionController.sentenceQuizViewData,
            onSubmit: _sessionController.sentenceQuizSubmit,
            onBack: _sessionController.openLiteracyMenu,
            onRestart: _sessionController.restartSentenceQuiz,
          ),
          SessionStatus.sentenceComposer => SentenceComposerScreen(
            viewData: _sessionController.sentenceComposerViewData,
            onSelectPerson: _sessionController.sentenceComposerSelectPerson,
            onSelectColor: _sessionController.sentenceComposerSelectColor,
            onSelectPiece: _sessionController.sentenceComposerSelectPiece,
            onSubmit: _sessionController.sentenceComposerSubmit,
            onBack: _sessionController.openLiteracyMenu,
            onRestart: _sessionController.restartSentenceComposer,
          ),
          SessionStatus.spellingQuiz => SpellingQuizScreen(
            viewData: _sessionController.spellingQuizViewData,
            onSubmit: _sessionController.spellingQuizSubmit,
            onPlayAudio: _sessionController.spellingQuizPlayAudio,
            onBack: _sessionController.openLiteracyMenu,
            onRestart: _sessionController.restartSpellingQuiz,
          ),
          SessionStatus.crossword => CrosswordScreen(
            viewData: _sessionController.crosswordViewData,
            onBack: _sessionController.openLiteracyMenu,
            onRestart: _sessionController.restartCrossword,
            onSelectLetter: _sessionController.crosswordSelectLetter,
            canPlace: _sessionController.crosswordCanPlace,
            onPlaceSelected: _sessionController.crosswordPlaceSelected,
            onPlace: _sessionController.crosswordPlace,
          ),
          SessionStatus.rating => RatingScreen(
            activity: _sessionController.ratingActivity,
            onRate: _sessionController.submitRating,
          ),
        },
      ),
    );
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }
}
