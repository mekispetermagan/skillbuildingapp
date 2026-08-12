import 'package:flutter/material.dart';

import 'controllers/session_controller.dart';
import 'models/letter_dragging_state.dart';
import 'screens/screens.dart';

void main() {
  runApp(const LiteracyApp());
}

class LiteracyApp extends StatelessWidget {
  const LiteracyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Literacy Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          dynamicSchemeVariant: DynamicSchemeVariant.rainbow,
        ),
      ),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => AppRootState();
}

class AppRootState extends State<AppRoot> {
  final SessionController _sessionController = SessionController();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _sessionController,
      builder: (_, _) => switch (_sessionController.status) {
        SessionStatus.menu => MenuScreen(
          menuItems: _sessionController.menuItems,
        ),
        SessionStatus.phraseBuilding => PhraseBuildingScreen(
          viewData: _sessionController.phraseBuildingViewData,
          onBack: _sessionController.openMenu,
          onMove: _sessionController.phraseBuildingMove,
          onSubmit: _sessionController.phraseBuildingSubmit,
          onPlayAudio: _sessionController.phraseBuildingPlayAudio,
        ),
        SessionStatus.letterDragging =>
          _sessionController.letterDraggingViewData.state ==
                  LetterDraggingState.result
              ? LetterDraggingResultScreen(
                  score: _sessionController.letterDraggingViewData.score,
                  onBack: _sessionController.openMenu,
                  onRestart: _sessionController.restartLetterDragging,
                )
              : LetterDraggingScreen(
                  viewData: _sessionController.letterDraggingViewData,
                  onBack: _sessionController.openMenu,
                  onReorder: _sessionController.letterDraggingReorder,
                  onPass: _sessionController.letterDraggingPass,
                ),
        SessionStatus.missingLetters => MissingLettersScreen(
          viewData: _sessionController.missingLettersViewData,
          onBack: _sessionController.openMenu,
          onNext: _sessionController.missingLettersNext,
          canDrop: _sessionController.missingLettersCanDrop,
          onDrop: _sessionController.missingLettersDrop,
        ),
        SessionStatus.letterShooting => LetterShootingScreen(
          viewData: _sessionController.letterShootingViewData,
          onResize: _sessionController.letterShootingResize,
          onTick: _sessionController.letterShootingTick,
          onTap: _sessionController.letterShootingTap,
          onBeginAim: _sessionController.letterShootingBeginAim,
          onUpdateAim: _sessionController.letterShootingUpdateAim,
          onReleaseAim: _sessionController.letterShootingReleaseAim,
          onBack: _sessionController.openMenu,
          onRestart: _sessionController.restartLetterShooting,
        ),
        SessionStatus.memory => MemoryScreen(
          viewData: _sessionController.memoryViewData,
          onBack: _sessionController.openMenu,
          onSelect: _sessionController.memorySelect,
          onNewGame: _sessionController.memoryStartNewGame,
        ),
        SessionStatus.letterCatching => LetterCatchingScreen(
          viewData: _sessionController.letterCatchingViewData,
          onResize: _sessionController.letterCatchingResize,
          onTick: _sessionController.letterCatchingTick,
          onMovePaddleBy: _sessionController.letterCatchingMovePaddleBy,
          onBack: _sessionController.openMenu,
          onRestart: _sessionController.restartLetterCatching,
        ),
        SessionStatus.conveyor => ConveyorScreen(
          viewData: _sessionController.conveyorViewData,
          onResize: _sessionController.conveyorResize,
          onTick: _sessionController.conveyorTick,
          canAccept: _sessionController.conveyorCanAccept,
          onStartDragging: _sessionController.conveyorStartDragging,
          onCancelDragging: _sessionController.conveyorCancelDragging,
          onDrop: _sessionController.conveyorDrop,
          onBack: _sessionController.openMenu,
          onRestart: _sessionController.restartConveyor,
        ),
        SessionStatus.sentenceQuiz => SentenceQuizScreen(
          viewData: _sessionController.sentenceQuizViewData,
          onSubmit: _sessionController.sentenceQuizSubmit,
          onBack: _sessionController.openMenu,
          onRestart: _sessionController.restartSentenceQuiz,
        ),
        SessionStatus.sentenceComposer => SentenceComposerScreen(
          viewData: _sessionController.sentenceComposerViewData,
          onSelectPerson: _sessionController.sentenceComposerSelectPerson,
          onSelectColor: _sessionController.sentenceComposerSelectColor,
          onSelectPiece: _sessionController.sentenceComposerSelectPiece,
          onSubmit: _sessionController.sentenceComposerSubmit,
          onBack: _sessionController.openMenu,
          onRestart: _sessionController.restartSentenceComposer,
        ),
        SessionStatus.spellingQuiz => SpellingQuizScreen(
          viewData: _sessionController.spellingQuizViewData,
          onSubmit: _sessionController.spellingQuizSubmit,
          onPlayAudio: _sessionController.spellingQuizPlayAudio,
          onBack: _sessionController.openMenu,
          onRestart: _sessionController.restartSpellingQuiz,
        ),
        SessionStatus.crossword => CrosswordScreen(
          viewData: _sessionController.crosswordViewData,
          onBack: _sessionController.openMenu,
          onRestart: _sessionController.restartCrossword,
          onSelectLetter: _sessionController.crosswordSelectLetter,
          canPlace: _sessionController.crosswordCanPlace,
          onPlaceSelected: _sessionController.crosswordPlaceSelected,
          onPlace: _sessionController.crosswordPlace,
        ),
      },
    );
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }
}
