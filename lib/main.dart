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
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
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
          isLoading: _sessionController.phraseBuildingIsLoading,
          errorMessage: _sessionController.phraseBuildingError,
          sourcePool: _sessionController.phraseBuildingSourcePool,
          targetPool: _sessionController.phraseBuildingTargetPool,
          state: _sessionController.phraseBuildingState,
          onBack: _sessionController.openMenu,
          onMove: _sessionController.phraseBuildingMove,
          onSubmit: _sessionController.phraseBuildingSubmit,
          onPlayAudio: _sessionController.phraseBuildingPlayAudio,
        ),
        SessionStatus.letterDragging =>
          _sessionController.letterDraggingState == LetterDraggingState.result
              ? LetterDraggingResultScreen(
                  score: _sessionController.letterDraggingScore,
                  onBack: _sessionController.openMenu,
                  onRestart: _sessionController.restartLetterDragging,
                )
              : LetterDraggingScreen(
                  isLoading: _sessionController.letterDraggingIsLoading,
                  errorMessage: _sessionController.letterDraggingError,
                  tiles: _sessionController.letterDraggingTiles,
                  state: _sessionController.letterDraggingState,
                  score: _sessionController.letterDraggingScore,
                  countdown: _sessionController.letterDraggingCountdown,
                  onBack: _sessionController.openMenu,
                  onReorder: _sessionController.letterDraggingReorder,
                  onPass: _sessionController.letterDraggingPass,
                ),
        SessionStatus.missingLetters => MissingLettersScreen(
          isLoading: _sessionController.missingLettersIsLoading,
          errorMessage: _sessionController.missingLettersError,
          slots: _sessionController.missingLetterSlots,
          pool: _sessionController.missingLetterPool,
          state: _sessionController.missingLettersState,
          score: _sessionController.missingLettersScore,
          onBack: _sessionController.openMenu,
          onNext: _sessionController.missingLettersNext,
          canDrop: _sessionController.missingLettersCanDrop,
          onDrop: _sessionController.missingLettersDrop,
        ),
        SessionStatus.letterShooting => LetterShootingScreen(
          isLoading: _sessionController.letterShootingIsLoading,
          errorMessage: _sessionController.letterShootingError,
          controller: _sessionController.letterShootingController,
          onBack: _sessionController.openMenu,
          onRestart: _sessionController.restartLetterShooting,
        ),
        SessionStatus.memory => MemoryScreen(
          isLoading: _sessionController.memoryIsLoading,
          errorMessage: _sessionController.memoryError,
          cards: _sessionController.memoryCards,
          isComplete: _sessionController.memoryIsComplete,
          onBack: _sessionController.openMenu,
          onSelect: _sessionController.memorySelect,
          onNewGame: _sessionController.memoryStartNewGame,
        ),
        SessionStatus.feature6 => Feature6Screen(
          onBack: _sessionController.openMenu,
        ),
        SessionStatus.feature7 => Feature7Screen(
          onBack: _sessionController.openMenu,
        ),
        SessionStatus.feature8 => Feature8Screen(
          onBack: _sessionController.openMenu,
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
