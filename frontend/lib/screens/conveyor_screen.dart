import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

import '../games/conveyor_game.dart';
import '../models/conveyor_state.dart';
import '../models/conveyor_config.dart';
import '../models/conveyor_world.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/conveyor_difficulty_segments.dart';
import '../widgets/feature_load_state.dart';
import '../widgets/game_end_overlay.dart';
import '../widgets/lives_display.dart';
import '../widgets/reward_gem_row.dart';

class ConveyorScreen extends StatelessWidget {
  final ConveyorViewData viewData;
  final void Function(double width, double height) onResize;
  final ConveyorState Function(double) onTick;
  final bool Function({required int letterId, required int shelfId}) canAccept;
  final ValueChanged<int> onStartDragging;
  final ValueChanged<int> onSelectLetter;
  final ValueChanged<int> onPlaceSelected;
  final ValueChanged<int> onCancelDragging;
  final void Function({required int letterId, required int shelfId}) onDrop;
  final VoidCallback onBack;
  final VoidCallback onRestart;
  final ValueChanged<ConveyorDifficulty> onSetDifficulty;

  const ConveyorScreen({
    required this.viewData,
    required this.onResize,
    required this.onTick,
    required this.canAccept,
    required this.onStartDragging,
    required this.onSelectLetter,
    required this.onPlaceSelected,
    required this.onCancelDragging,
    required this.onDrop,
    required this.onBack,
    required this.onRestart,
    required this.onSetDifficulty,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(
      title: context.l10n.activityWordConveyor,
      onBack: onBack,
    ),
    body: FeatureLoadState(
      isLoading: viewData.isLoading,
      loadError: viewData.loadError,
      child: switch (viewData.world) {
        final ConveyorWorld world => SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: ConveyorDifficultySegments(
                  value: viewData.difficulty,
                  onChanged: onSetDifficulty,
                ),
              ),
              Expanded(
                child: _ConveyorPlayArea(
                  initialState: viewData.state,
                  world: world,
                  onResize: onResize,
                  onTick: onTick,
                  canAccept: canAccept,
                  onStartDragging: onStartDragging,
                  onSelectLetter: onSelectLetter,
                  onPlaceSelected: onPlaceSelected,
                  selectedLetterId: viewData.selectedLetterId,
                  onCancelDragging: onCancelDragging,
                  onDrop: onDrop,
                  onRestart: onRestart,
                ),
              ),
            ],
          ),
        ),
        null => const SizedBox.shrink(),
      },
    ),
  );
}

class _ConveyorPlayArea extends StatefulWidget {
  final ConveyorState initialState;
  final ConveyorWorld world;
  final void Function(double width, double height) onResize;
  final ConveyorState Function(double) onTick;
  final bool Function({required int letterId, required int shelfId}) canAccept;
  final ValueChanged<int> onStartDragging;
  final ValueChanged<int> onSelectLetter;
  final ValueChanged<int> onPlaceSelected;
  final int? selectedLetterId;
  final ValueChanged<int> onCancelDragging;
  final void Function({required int letterId, required int shelfId}) onDrop;
  final VoidCallback onRestart;

  const _ConveyorPlayArea({
    required this.initialState,
    required this.world,
    required this.onResize,
    required this.onTick,
    required this.canAccept,
    required this.onStartDragging,
    required this.onSelectLetter,
    required this.onPlaceSelected,
    required this.selectedLetterId,
    required this.onCancelDragging,
    required this.onDrop,
    required this.onRestart,
  });

  @override
  State<_ConveyorPlayArea> createState() => _ConveyorPlayAreaState();
}

class _ConveyorPlayAreaState extends State<_ConveyorPlayArea> {
  late ConveyorState _state = widget.initialState;
  final ValueNotifier<int> _frame = ValueNotifier(0);
  late final ConveyorGame _game = ConveyorGame(
    gameWorld: widget.world,
    onResize: widget.onResize,
    onTick: widget.onTick,
    onFrame: _refreshFrame,
  );

  void _refreshFrame(ConveyorState state) {
    if (!mounted) return;
    _state = state;
    _frame.value++;
  }

  @override
  void dispose() {
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: ClipRect(
          child: Stack(
            children: [
              Positioned.fill(child: GameWidget(game: _game)),
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: _frame,
                  builder: (_, _) => _MovingPieces(
                    world: widget.world,
                    canAccept: widget.canAccept,
                    onStartDragging: widget.onStartDragging,
                    onSelectLetter: widget.onSelectLetter,
                    onPlaceSelected: widget.onPlaceSelected,
                    selectedLetterId: widget.selectedLetterId,
                    onCancelDragging: widget.onCancelDragging,
                    onDrop: widget.onDrop,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 12,
                child: IgnorePointer(
                  child: ListenableBuilder(
                    listenable: _frame,
                    builder: (_, _) => LivesDisplay(
                      lives: widget.world.lives,
                      maximumLives: widget.world.config.startingLives,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: _frame,
                  builder: (_, _) => switch (_state) {
                    ConveyorState.playing => const SizedBox.shrink(),
                    ConveyorState.won => GameEndOverlay(
                      message: context.l10n.congratulations,
                      onRestart: widget.onRestart,
                    ),
                    ConveyorState.lost => GameEndOverlay(
                      message: context.l10n.sorry,
                      onRestart: widget.onRestart,
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      ListenableBuilder(
        listenable: _frame,
        builder: (_, _) => RewardGemRow(count: widget.world.score),
      ),
    ],
  );
}

class _MovingPieces extends StatelessWidget {
  final ConveyorWorld world;
  final bool Function({required int letterId, required int shelfId}) canAccept;
  final ValueChanged<int> onStartDragging;
  final ValueChanged<int> onSelectLetter;
  final ValueChanged<int> onPlaceSelected;
  final int? selectedLetterId;
  final ValueChanged<int> onCancelDragging;
  final void Function({required int letterId, required int shelfId}) onDrop;

  const _MovingPieces({
    required this.world,
    required this.canAccept,
    required this.onStartDragging,
    required this.onSelectLetter,
    required this.onPlaceSelected,
    required this.selectedLetterId,
    required this.onCancelDragging,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        for (final shelf in world.shelves)
          Positioned(
            key: ValueKey('shelf-${shelf.id}'),
            left: world.leftBeltX + 5,
            top: shelf.y,
            width: world.leftBeltWidth - 10,
            height: world.config.shelfHeight,
            child: DragTarget<int>(
              onWillAcceptWithDetails: (details) =>
                  canAccept(letterId: details.data, shelfId: shelf.id),
              onAcceptWithDetails: (details) =>
                  onDrop(letterId: details.data, shelfId: shelf.id),
              builder: (_, candidates, _) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: selectedLetterId == null
                    ? null
                    : () => onPlaceSelected(shelf.id),
                child: _ShelfCard(
                  shelf: shelf,
                  isHovering: candidates.isNotEmpty,
                ),
              ),
            ),
          ),
        for (final letter in world.letters)
          Positioned(
            key: ValueKey('letter-${letter.id}'),
            left:
                world.rightBeltX +
                (world.config.rightBeltWidth - world.config.letterSize) / 2,
            top: letter.y,
            width: world.config.letterSize,
            height: world.config.letterSize,
            child: Draggable<int>(
              data: letter.id,
              onDragStarted: () => onStartDragging(letter.id),
              onDraggableCanceled: (_, _) => onCancelDragging(letter.id),
              onDragEnd: (details) {
                if (!details.wasAccepted) {
                  onCancelDragging(letter.id);
                }
              },
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox.square(
                  dimension: world.config.letterSize,
                  child: _LetterCard(letter: letter.letter),
                ),
              ),
              childWhenDragging: const SizedBox.shrink(),
              child: GestureDetector(
                onTap: () => onSelectLetter(letter.id),
                child: _LetterCard(
                  letter: letter.letter,
                  isSelected: selectedLetterId == letter.id,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ShelfCard extends StatelessWidget {
  final ConveyorShelf shelf;
  final bool isHovering;

  const _ShelfCard({required this.shelf, required this.isHovering});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: isHovering ? const Color(0xff455a64) : const Color(0xff303740),
      border: Border.all(
        color: shelf.isComplete
            ? const Color(0xff66bb6a)
            : const Color(0xff8b949e),
        width: 2,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(7),
      child: Row(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Image.asset(shelf.word.imagePath, fit: BoxFit.contain),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                shelf.displayWord,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: shelf.isComplete
                      ? const Color(0xff81c784)
                      : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _LetterCard extends StatelessWidget {
  final String letter;
  final bool isSelected;

  const _LetterCard({required this.letter, this.isSelected = false});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xff5e35b1),
      border: Border.all(
        color: isSelected ? Colors.amberAccent : Colors.white70,
        width: isSelected ? 4 : 2,
      ),
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
      ],
    ),
    child: Center(
      child: Text(
        letter,
        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
