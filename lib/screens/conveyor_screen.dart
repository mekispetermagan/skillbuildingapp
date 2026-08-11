import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../games/conveyor_game.dart';
import '../models/conveyor_world.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/feature_load_state.dart';
import '../widgets/game_end_overlay.dart';
import '../widgets/lives_display.dart';
import '../widgets/reward_row.dart';

class ConveyorScreen extends StatelessWidget {
  final ConveyorViewData viewData;
  final ValueGetter<ConveyorViewData> readViewData;
  final void Function(double width, double height) onResize;
  final ValueChanged<double> onTick;
  final bool Function({required int letterId, required int shelfId}) canAccept;
  final ValueChanged<int> onStartDragging;
  final ValueChanged<int> onCancelDragging;
  final void Function({required int letterId, required int shelfId}) onDrop;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  const ConveyorScreen({
    required this.viewData,
    required this.readViewData,
    required this.onResize,
    required this.onTick,
    required this.canAccept,
    required this.onStartDragging,
    required this.onCancelDragging,
    required this.onDrop,
    required this.onBack,
    required this.onRestart,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(title: 'Word conveyor', onBack: onBack),
    body: FeatureLoadState(
      isLoading: viewData.isLoading,
      errorMessage: viewData.errorMessage,
      child: switch (viewData.world) {
        final ConveyorWorld world => SafeArea(
          child: _ConveyorPlayArea(
            initialViewData: viewData,
            world: world,
            readViewData: readViewData,
            onResize: onResize,
            onTick: onTick,
            canAccept: canAccept,
            onStartDragging: onStartDragging,
            onCancelDragging: onCancelDragging,
            onDrop: onDrop,
            onRestart: onRestart,
          ),
        ),
        null => const SizedBox.shrink(),
      },
    ),
  );
}

class _ConveyorPlayArea extends StatefulWidget {
  final ConveyorViewData initialViewData;
  final ConveyorWorld world;
  final ValueGetter<ConveyorViewData> readViewData;
  final void Function(double width, double height) onResize;
  final ValueChanged<double> onTick;
  final bool Function({required int letterId, required int shelfId}) canAccept;
  final ValueChanged<int> onStartDragging;
  final ValueChanged<int> onCancelDragging;
  final void Function({required int letterId, required int shelfId}) onDrop;
  final VoidCallback onRestart;

  const _ConveyorPlayArea({
    required this.initialViewData,
    required this.world,
    required this.readViewData,
    required this.onResize,
    required this.onTick,
    required this.canAccept,
    required this.onStartDragging,
    required this.onCancelDragging,
    required this.onDrop,
    required this.onRestart,
  });

  @override
  State<_ConveyorPlayArea> createState() => _ConveyorPlayAreaState();
}

class _ConveyorPlayAreaState extends State<_ConveyorPlayArea> {
  late ConveyorViewData _viewData = widget.initialViewData;
  final ValueNotifier<int> _frame = ValueNotifier(0);
  late final ConveyorGame _game = ConveyorGame(
    gameWorld: widget.world,
    onResize: widget.onResize,
    onTick: widget.onTick,
    onFrame: _refreshFrame,
  );

  void _refreshFrame() {
    if (!mounted) return;
    _viewData = widget.readViewData();
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
                  builder: (_, _) => switch (_viewData.state) {
                    ConveyorState.playing => const SizedBox.shrink(),
                    ConveyorState.won => GameEndOverlay(
                      message: 'Congratulations!',
                      onRestart: widget.onRestart,
                    ),
                    ConveyorState.lost => GameEndOverlay(
                      message: 'Sorry!',
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
        builder: (_, _) => RewardRow(count: widget.world.score),
      ),
    ],
  );
}

class _MovingPieces extends StatelessWidget {
  final ConveyorWorld world;
  final bool Function({required int letterId, required int shelfId}) canAccept;
  final ValueChanged<int> onStartDragging;
  final ValueChanged<int> onCancelDragging;
  final void Function({required int letterId, required int shelfId}) onDrop;

  const _MovingPieces({
    required this.world,
    required this.canAccept,
    required this.onStartDragging,
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
              builder: (_, candidates, _) =>
                  _ShelfCard(shelf: shelf, isHovering: candidates.isNotEmpty),
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
              child: _LetterCard(letter: letter.letter),
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
                _displayWord(),
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

  String _displayWord() {
    final buffer = StringBuffer();
    for (var index = 0; index < shelf.word.word.length; index++) {
      final hidden =
          shelf.missingIndices.contains(index) &&
          !shelf.recoveredIndices.contains(index);
      buffer.write(hidden ? '❓' : shelf.word.word[index]);
    }
    return buffer.toString();
  }
}

class _LetterCard extends StatelessWidget {
  final String letter;

  const _LetterCard({required this.letter});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xff5e35b1),
      border: Border.all(color: Colors.white70, width: 2),
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
