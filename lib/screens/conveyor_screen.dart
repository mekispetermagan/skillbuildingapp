import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../controllers/conveyor_controller.dart';
import '../games/conveyor_game.dart';
import '../models/conveyor_world.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/rewards.dart';

class ConveyorScreen extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final ConveyorController? controller;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  const ConveyorScreen({
    required this.isLoading,
    required this.errorMessage,
    required this.controller,
    required this.onBack,
    required this.onRestart,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(title: 'Word conveyor', onBack: onBack),
    body: switch ((isLoading, errorMessage, controller)) {
      (true, _, _) => const Center(child: CircularProgressIndicator()),
      (_, final String message, _) => Center(child: Text(message)),
      (_, _, final ConveyorController controller) => SafeArea(
        child: _ConveyorPlayArea(controller: controller, onRestart: onRestart),
      ),
      _ => const SizedBox.shrink(),
    },
  );
}

class _ConveyorPlayArea extends StatefulWidget {
  final ConveyorController controller;
  final VoidCallback onRestart;

  const _ConveyorPlayArea({required this.controller, required this.onRestart});

  @override
  State<_ConveyorPlayArea> createState() => _ConveyorPlayAreaState();
}

class _ConveyorPlayAreaState extends State<_ConveyorPlayArea> {
  late final ConveyorGame _game = ConveyorGame(widget.controller);

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
                  listenable: widget.controller,
                  builder: (_, _) =>
                      _MovingPieces(controller: widget.controller),
                ),
              ),
              Positioned(
                top: 10,
                right: 12,
                child: IgnorePointer(
                  child: ListenableBuilder(
                    listenable: widget.controller,
                    builder: (_, _) => Text(
                      _livesText(),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: widget.controller,
                  builder: (_, _) => switch (widget.controller.state) {
                    ConveyorState.playing => const SizedBox.shrink(),
                    ConveyorState.won => _EndOverlay(
                      message: 'Congratulations!',
                      onRestart: widget.onRestart,
                    ),
                    ConveyorState.lost => _EndOverlay(
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
      SizedBox(
        height: 46,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (_, _) => Rewards(count: widget.controller.world.score),
        ),
      ),
    ],
  );

  String _livesText() {
    final world = widget.controller.world;
    return [
      ...List.filled(world.lives, '❤️'),
      ...List.filled(world.config.startingLives - world.lives, '💔'),
    ].join();
  }
}

class _MovingPieces extends StatelessWidget {
  final ConveyorController controller;

  const _MovingPieces({required this.controller});

  @override
  Widget build(BuildContext context) {
    final world = controller.world;
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
              onWillAcceptWithDetails: (details) => controller.canAccept(
                letterId: details.data,
                shelfId: shelf.id,
              ),
              onAcceptWithDetails: (details) =>
                  controller.drop(letterId: details.data, shelfId: shelf.id),
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
              onDragStarted: () => controller.startDragging(letter.id),
              onDraggableCanceled: (_, _) =>
                  controller.cancelDragging(letter.id),
              onDragEnd: (details) {
                if (!details.wasAccepted) {
                  controller.cancelDragging(letter.id);
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

class _EndOverlay extends StatelessWidget {
  final String message;
  final VoidCallback onRestart;

  const _EndOverlay({required this.message, required this.onRestart});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black54,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          FilledButton(onPressed: onRestart, child: const Text('Play again?')),
        ],
      ),
    ),
  );
}
