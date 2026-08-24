import 'dart:async';

import 'package:flutter/material.dart';

import 'api/gameplay_api_client.dart';
import 'api/authentication_api_client.dart';
import 'api/student_api_client.dart';
import 'api/student_group_api_client.dart';
import 'config/gameplay_api_config.dart';
import 'controllers/session_controller.dart';
import 'controllers/account_flow_controller.dart';
import 'l10n/l10n.dart';
import 'models/letter_dragging_state.dart';
import 'models/authentication.dart';
import 'models/interface_language.dart';
import 'models/play_record.dart';
import 'screens/screens.dart';
import 'services/gameplay_recorder.dart';
import 'storage/gameplay_record_store.dart';
import 'theme/app_theme.dart';
import 'widgets/account_menu.dart';

void main() {
  final config = GameplayApiConfig.fromEnvironment();
  final recorder = SyncedGameplayRecorder(
    SharedPreferencesGameplayRecordStore(),
    GameplayApiClient(config: config),
  );
  runApp(
    LiteracyApp(
      gameplayRecorder: recorder,
      authenticationApi: AuthenticationApiClient(config: config),
      studentApi: StudentApiClient(config: config),
      studentGroupApi: StudentGroupApiClient(config: config),
    ),
  );
}

class LiteracyApp extends StatefulWidget {
  final GameplayRecorder gameplayRecorder;
  final AuthenticationApi? authenticationApi;
  final bool authenticationEnabled;
  final StudentApi? studentApi;
  final StudentGroupApi? studentGroupApi;

  const LiteracyApp({
    this.gameplayRecorder = const NoopGameplayRecorder(),
    this.authenticationApi,
    this.authenticationEnabled = true,
    this.studentApi,
    this.studentGroupApi,
    super.key,
  });

  @override
  State<LiteracyApp> createState() => _LiteracyAppState();
}

class _LiteracyAppState extends State<LiteracyApp> {
  InterfaceLanguage _language = InterfaceLanguage.english;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _language.locale,
      onGenerateTitle: (context) => context.l10n.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      home: widget.authenticationEnabled
          ? AccountGateway(
              gameplayRecorder: widget.gameplayRecorder,
              authenticationApi:
                  widget.authenticationApi ??
                  AuthenticationApiClient(
                    config: GameplayApiConfig.fromEnvironment(),
                  ),
              onLanguageChanged: (language) {
                if (_language != language) setState(() => _language = language);
              },
              studentApi: widget.studentApi,
              studentGroupApi: widget.studentGroupApi,
            )
          : AppRoot(
              gameplayRecorder: widget.gameplayRecorder,
              language: _language,
            ),
    );
  }
}

class AccountGateway extends StatefulWidget {
  final GameplayRecorder gameplayRecorder;
  final AuthenticationApi authenticationApi;
  final ValueChanged<InterfaceLanguage> onLanguageChanged;
  final StudentApi? studentApi;
  final StudentGroupApi? studentGroupApi;

  const AccountGateway({
    required this.gameplayRecorder,
    required this.authenticationApi,
    required this.onLanguageChanged,
    this.studentApi,
    this.studentGroupApi,
    super.key,
  });

  @override
  State<AccountGateway> createState() => _AccountGatewayState();
}

class _AccountGatewayState extends State<AccountGateway> {
  late final AccountFlowController _controller = AccountFlowController(
    widget.authenticationApi,
    studentApi: widget.studentApi,
    groupApi: widget.studentGroupApi,
  );
  Timer? _timeoutTimer;
  InterfaceLanguage? _reportedLanguage;
  final GlobalKey<AppRootState> _gameKey = GlobalKey<AppRootState>();

  @override
  void initState() {
    super.initState();
    _controller.initialize();
    _controller.addListener(_reportLanguage);
    _controller.addListener(_reportPlayer);
    _timeoutTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      if (_controller.checkTeacherTimeout()) return;
      await _controller.synchronizeStudents();
      await _controller.synchronizeAccountPreferences();
      await widget.gameplayRecorder.synchronize();
    });
  }

  void _reportLanguage() {
    final language = _controller.account?.preferredLanguage;
    if (language != null && language != _reportedLanguage) {
      _reportedLanguage = language;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onLanguageChanged(language);
      });
    }
  }

  void _reportPlayer() {
    final recorder = widget.gameplayRecorder;
    if (recorder is! PlayerAwareGameplayRecorder) return;
    final playerAwareRecorder = recorder as PlayerAwareGameplayRecorder;
    final account = _controller.account;
    if (account == null) {
      playerAwareRecorder.setPlayer(null);
    } else if (account.role == AccountRole.learner) {
      playerAwareRecorder.setPlayer(
        GameplayPlayer.learner(account.accessToken),
      );
    } else {
      final student = _controller.selectedStudent;
      playerAwareRecorder.setPlayer(
        student == null
            ? null
            : GameplayPlayer.student(student.id, account.accessToken),
      );
    }
  }

  void _changeStudent() {
    if (_gameKey.currentState?.exitToAccount(_controller.leaveGames) != true) {
      _controller.leaveGames();
    }
  }

  void _logout() {
    if (_controller.page == AccountFlowPage.games) {
      if (_gameKey.currentState?.exitToAccount(_controller.logout) == true) {
        return;
      }
    }
    _controller.logout();
  }

  Widget _page(BuildContext context) => switch (_controller.page) {
    AccountFlowPage.opening => OpeningScreen(onStart: _controller.start),
    AccountFlowPage.welcome => AuthenticationWelcomeScreen(
      onLogin: _controller.showLogin,
      onRegister: _controller.showRegistration,
      onBack: _controller.back,
    ),
    AccountFlowPage.login => LoginScreen(
      busy: _controller.busy,
      errorMessage: _controller.errorMessage,
      onSubmit: _controller.login,
      onBack: _controller.back,
    ),
    AccountFlowPage.register => RegistrationScreen(
      busy: _controller.busy,
      errorMessage: _controller.errorMessage,
      onSubmit: _controller.register,
      onBack: _controller.back,
    ),
    AccountFlowPage.students => StudentMenuScreen(
      teacherName: _controller.account!.name,
      ungroupedStudents: _controller.ungroupedStudents,
      groups: _controller.groups,
      onSelect: _controller.selectStudent,
      onEdit: _controller.editStudent,
      onAddStudent: _controller.addStudent,
      onAddGroup: _controller.addGroup,
      onOpenGroup: _controller.openGroup,
      onJoinGroup: _controller.showJoinGroup,
    ),
    AccountFlowPage.studentForm => StudentFormScreen(
      student: _controller.editingStudent,
      onSave: _controller.saveStudent,
      onBack: _controller.back,
    ),
    AccountFlowPage.groupForm => GroupFormScreen(
      group: _controller.editingGroup,
      onSave: _controller.saveGroup,
      onBack: _controller.back,
    ),
    AccountFlowPage.groupStudents => GroupStudentsScreen(
      group: _controller.selectedGroup!,
      students: _controller.selectedGroupStudents,
      busy: _controller.busy,
      errorMessage: _controller.errorMessage,
      onSelect: _controller.selectStudent,
      onEditStudent: _controller.editStudent,
      onRemoveStudent: _controller.removeStudentFromSelectedGroup,
      onCreateStudent: () =>
          _controller.addStudent(groupId: _controller.selectedGroup!.id),
      onAddExistingStudents: _controller.showAddStudentsToGroup,
      onRename: _controller.editSelectedGroup,
      onShare: _controller.generateSelectedGroupShareCode,
      onBack: _controller.back,
    ),
    AccountFlowPage.groupAddStudents => GroupStudentPickerScreen(
      groupName: _controller.selectedGroup!.name,
      students: _controller.studentsOutsideSelectedGroup,
      onAdd: _controller.addStudentsToSelectedGroup,
      onBack: _controller.back,
    ),
    AccountFlowPage.groupJoin => JoinGroupScreen(
      busy: _controller.busy,
      errorMessage: _controller.errorMessage,
      onJoin: _controller.joinGroup,
      onBack: _controller.back,
    ),
    AccountFlowPage.language => LanguageSelectionScreen(
      selectedLanguage: _controller.account!.preferredLanguage,
      onSelect: _controller.changeLanguage,
      onBack: _controller.closeLanguage,
    ),
    AccountFlowPage.games => AppRoot(
      key: _gameKey,
      gameplayRecorder: widget.gameplayRecorder,
      language: _controller.account!.preferredLanguage,
      startAtAreaMenu: true,
      onExit: _controller.account!.role == AccountRole.teacher
          ? _controller.leaveGames
          : null,
    ),
  };

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _controller.recordActivity(),
    child: ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final page = _page(context);
        final account = _controller.account;
        if (account == null || _controller.page == AccountFlowPage.language) {
          return page;
        }
        return AccountMenuScope(
          onChangeLanguage: _controller.showLanguage,
          onChangeStudent:
              account.role == AccountRole.teacher &&
                  _controller.page == AccountFlowPage.games
              ? _changeStudent
              : null,
          onLogout: _logout,
          child: page,
        );
      },
    ),
  );

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _controller.removeListener(_reportLanguage);
    _controller.removeListener(_reportPlayer);
    _controller.dispose();
    super.dispose();
  }
}

class AppRoot extends StatefulWidget {
  final GameplayRecorder gameplayRecorder;
  final bool startAtAreaMenu;
  final VoidCallback? onExit;
  final InterfaceLanguage language;

  const AppRoot({
    this.gameplayRecorder = const NoopGameplayRecorder(),
    this.startAtAreaMenu = false,
    this.onExit,
    this.language = InterfaceLanguage.english,
    super.key,
  });

  @override
  State<AppRoot> createState() => AppRootState();
}

class AppRootState extends State<AppRoot> {
  late final SessionController _sessionController;

  @override
  void initState() {
    super.initState();
    _sessionController = SessionController(
      gameplayRecorder: widget.gameplayRecorder,
      language: widget.language,
    );
    if (widget.startAtAreaMenu) _sessionController.openAreaMenu();
  }

  bool exitToAccount(VoidCallback destination) {
    if (!_sessionController.canExitAccount) return false;
    _sessionController.exitAccount();
    destination();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _sessionController,
      builder: (_, _) => PopScope(
        canPop: _sessionController.status == SessionStatus.opening,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop &&
              _sessionController.status == SessionStatus.areaMenu &&
              widget.onExit != null) {
            widget.onExit!();
          } else if (!didPop &&
              _sessionController.status != SessionStatus.rating) {
            _sessionController.handleBack();
          }
        },
        child: switch (_sessionController.status) {
          SessionStatus.opening => OpeningScreen(
            onStart: _sessionController.openAreaMenu,
          ),
          SessionStatus.areaMenu => AreaMenuScreen(
            onOpenLiteracy: _sessionController.openLiteracyMenu,
            onOpenMath: _sessionController.openMathMenu,
          ),
          SessionStatus.literacyMenu => LiteracyMenuScreen(
            menuItems: _sessionController.literacyMenuItems,
            onBack: _sessionController.handleBack,
          ),
          SessionStatus.mathMenu => MathMenuScreen(
            menuItems: _sessionController.mathMenuItems,
            onBack: _sessionController.handleBack,
          ),
          SessionStatus.mathPlaceholder => MathPlaceholderScreen(
            featureNumber: _sessionController.mathPlaceholderNumber!,
            onBack: _sessionController.handleBack,
          ),
          SessionStatus.numberLearning => NumberLearningScreen(
            viewData: _sessionController.numberLearningViewData,
            onBack: _sessionController.handleBack,
            onSetRange: _sessionController.numberLearningSetRange,
            onSetUseColors: _sessionController.numberLearningSetUseColors,
            onGuess: _sessionController.numberLearningGuess,
          ),
          SessionStatus.numberComparison => NumberComparisonScreen(
            viewData: _sessionController.numberComparisonViewData,
            onBack: _sessionController.handleBack,
            onSetRange: _sessionController.numberComparisonSetRange,
            onSetArrangement: _sessionController.numberComparisonSetArrangement,
            onGuess: _sessionController.numberComparisonGuess,
          ),
          SessionStatus.operationsPractice => OperationsPracticeScreen(
            viewData: _sessionController.operationsPracticeViewData,
            onBack: _sessionController.handleBack,
            onSetOperators: _sessionController.operationsPracticeSetOperators,
            onSetRange: _sessionController.operationsPracticeSetRange,
            onSetUseColors: _sessionController.operationsPracticeSetUseColors,
            onGuess: _sessionController.operationsPracticeGuess,
          ),
          SessionStatus.numberDragging =>
            _sessionController.numberDraggingViewData.state ==
                    LetterDraggingState.result
                ? NumberDraggingResultScreen(
                    score: _sessionController.numberDraggingViewData.score,
                    onBack: _sessionController.handleBack,
                    onRestart: _sessionController.restartNumberDragging,
                  )
                : NumberDraggingScreen(
                    viewData: _sessionController.numberDraggingViewData,
                    onBack: _sessionController.handleBack,
                    onReorder: _sessionController.numberDraggingReorder,
                    onPass: _sessionController.numberDraggingPass,
                    onSetRange: _sessionController.numberDraggingSetRange,
                  ),
          SessionStatus.numberMemory => NumberMemoryScreen(
            viewData: _sessionController.numberMemoryViewData,
            onBack: _sessionController.handleBack,
            onSelect: _sessionController.numberMemorySelect,
            onNewGame: _sessionController.numberMemoryStartNewGame,
            onSetRange: _sessionController.numberMemorySetRange,
          ),
          SessionStatus.balanceGame => BalanceGameScreen(
            viewData: _sessionController.balanceGameViewData,
            onBack: _sessionController.handleBack,
            onSelectStone: _sessionController.balanceGameSelectStone,
          ),
          SessionStatus.logicGame => LogicGameScreen(
            viewData: _sessionController.logicGameViewData,
            onBack: _sessionController.handleBack,
            onSetDifficulty: _sessionController.logicGameSetDifficulty,
            onPlace: _sessionController.logicGamePlace,
          ),
          SessionStatus.shoppingGame => ShoppingGameScreen(
            viewData: _sessionController.shoppingGameViewData,
            onBack: _sessionController.handleBack,
            onToggleCashRegister:
                _sessionController.shoppingGameToggleCashRegister,
            onNotEnough: _sessionController.shoppingGameAnswerNotEnough,
            onTakeBalance: _sessionController.shoppingGameAnswerTakeBalance,
            onAddBalanceNote: _sessionController.shoppingGameAddBalanceNote,
            onRemoveBalanceNote:
                _sessionController.shoppingGameRemoveBalanceNote,
          ),
          SessionStatus.operatorConveyor => OperatorConveyorScreen(
            viewData: _sessionController.operatorConveyorViewData,
            onResize: _sessionController.operatorConveyorResize,
            onTick: _sessionController.operatorConveyorTick,
            canAccept: _sessionController.operatorConveyorCanAccept,
            onStartDragging: _sessionController.operatorConveyorStartDragging,
            onSelectOperator: _sessionController.operatorConveyorSelectOperator,
            onPlaceSelected: _sessionController.operatorConveyorPlaceSelected,
            onCancelDragging: _sessionController.operatorConveyorCancelDragging,
            onDrop: _sessionController.operatorConveyorDrop,
            onBack: _sessionController.handleBack,
            onRestart: _sessionController.restartOperatorConveyor,
            onSetDifficulty: _sessionController.operatorConveyorSetDifficulty,
          ),
          SessionStatus.evenOdd => EvenOddScreen(
            viewData: _sessionController.evenOddViewData,
            onResize: _sessionController.evenOddResize,
            onTick: _sessionController.evenOddTick,
            onMovePaddleBy: _sessionController.evenOddMovePaddleBy,
            onToggleParity: _sessionController.evenOddToggleParity,
            onBack: _sessionController.handleBack,
            onRestart: _sessionController.restartEvenOdd,
          ),
          SessionStatus.letterLearning => LetterLearningScreen(
            viewData: _sessionController.letterLearningViewData,
            onBack: _sessionController.handleBack,
            onRestart: _sessionController.restartLetterLearning,
            onSetTiers: _sessionController.letterLearningSetTiers,
            onSetMode: _sessionController.letterLearningSetMode,
            onGuess: _sessionController.letterLearningGuess,
            onSelectLetter: _sessionController.letterLearningSelectLetter,
            onGuessSelected: _sessionController.letterLearningGuessSelected,
            onPlayAudio: _sessionController.letterLearningPlayAudio,
          ),
          SessionStatus.letterPractice => LetterPracticeScreen(
            viewData: _sessionController.letterPracticeViewData,
            onBack: _sessionController.handleBack,
            onRestart: _sessionController.restartLetterPractice,
            onSetTiers: _sessionController.letterPracticeSetTiers,
            onSetWordSet: _sessionController.letterPracticeSetWordSet,
            onSetUseColors: _sessionController.letterPracticeSetUseColors,
            onSelectLetter: _sessionController.letterPracticeSelectLetter,
            canPlace: _sessionController.letterPracticeCanPlace,
            onPlaceSelected: _sessionController.letterPracticePlaceSelected,
            onPlace: _sessionController.letterPracticePlace,
            onPlayAudio: _sessionController.letterPracticePlayAudio,
          ),
          SessionStatus.phraseBuilding => PhraseBuildingScreen(
            viewData: _sessionController.phraseBuildingViewData,
            onBack: _sessionController.handleBack,
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
                    onBack: _sessionController.handleBack,
                    onRestart: _sessionController.restartLetterDragging,
                  )
                : LetterDraggingScreen(
                    viewData: _sessionController.letterDraggingViewData,
                    onBack: _sessionController.handleBack,
                    onReorder: _sessionController.letterDraggingReorder,
                    onPass: _sessionController.letterDraggingPass,
                    onShowImagesChanged:
                        _sessionController.letterDraggingSetShowImages,
                  ),
          SessionStatus.missingLetters => MissingLettersScreen(
            viewData: _sessionController.missingLettersViewData,
            onBack: _sessionController.handleBack,
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
            onBack: _sessionController.handleBack,
            onRestart: _sessionController.restartLetterShooting,
          ),
          SessionStatus.memory => MemoryScreen(
            viewData: _sessionController.memoryViewData,
            onBack: _sessionController.handleBack,
            onSelect: _sessionController.memorySelect,
            onNewGame: _sessionController.memoryStartNewGame,
          ),
          SessionStatus.letterCatching => LetterCatchingScreen(
            viewData: _sessionController.letterCatchingViewData,
            onResize: _sessionController.letterCatchingResize,
            onTick: _sessionController.letterCatchingTick,
            onMovePaddleBy: _sessionController.letterCatchingMovePaddleBy,
            onBack: _sessionController.handleBack,
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
            onBack: _sessionController.handleBack,
            onRestart: _sessionController.restartConveyor,
            onSetDifficulty: _sessionController.conveyorSetDifficulty,
          ),
          SessionStatus.sentenceQuiz => SentenceQuizScreen(
            viewData: _sessionController.sentenceQuizViewData,
            onSubmit: _sessionController.sentenceQuizSubmit,
            onBack: _sessionController.handleBack,
            onRestart: _sessionController.restartSentenceQuiz,
          ),
          SessionStatus.sentenceComposer => SentenceComposerScreen(
            viewData: _sessionController.sentenceComposerViewData,
            onSelectPerson: _sessionController.sentenceComposerSelectPerson,
            onSelectColor: _sessionController.sentenceComposerSelectColor,
            onSelectPiece: _sessionController.sentenceComposerSelectPiece,
            onSubmit: _sessionController.sentenceComposerSubmit,
            onBack: _sessionController.handleBack,
            onRestart: _sessionController.restartSentenceComposer,
          ),
          SessionStatus.spellingQuiz => SpellingQuizScreen(
            viewData: _sessionController.spellingQuizViewData,
            onSubmit: _sessionController.spellingQuizSubmit,
            onPlayAudio: _sessionController.spellingQuizPlayAudio,
            onBack: _sessionController.handleBack,
            onRestart: _sessionController.restartSpellingQuiz,
          ),
          SessionStatus.crossword => CrosswordScreen(
            viewData: _sessionController.crosswordViewData,
            onBack: _sessionController.handleBack,
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
