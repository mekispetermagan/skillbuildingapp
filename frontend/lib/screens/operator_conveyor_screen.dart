import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../games/conveyor_game.dart';
import '../l10n/l10n.dart';
import '../models/conveyor_state.dart';
import '../models/conveyor_config.dart';
import '../models/operator_conveyor_world.dart';
import '../models/math_notation.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/conveyor_difficulty_segments.dart';
import '../widgets/game_end_overlay.dart';
import '../widgets/lives_display.dart';
import '../widgets/reward_gem_row.dart';

class OperatorConveyorScreen extends StatelessWidget {
  final OperatorConveyorViewData viewData;
  final void Function(double width, double height) onResize;
  final ConveyorState Function(double) onTick;
  final bool Function({required int operatorId, required int shelfId})
  canAccept;
  final ValueChanged<int> onStartDragging;
  final ValueChanged<int> onSelectOperator;
  final ValueChanged<int> onPlaceSelected;
  final ValueChanged<int> onCancelDragging;
  final void Function({required int operatorId, required int shelfId}) onDrop;
  final VoidCallback onBack;
  final VoidCallback onRestart;
  final ValueChanged<ConveyorDifficulty> onSetDifficulty;

  const OperatorConveyorScreen({
    required this.viewData,
    required this.onResize,
    required this.onTick,
    required this.canAccept,
    required this.onStartDragging,
    required this.onSelectOperator,
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
      title: context.l10n.activityOperatorConveyor,
      onBack: onBack,
    ),
    body: SafeArea(
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
            child: _OperatorConveyorPlayArea(
              initialState: viewData.state,
              world: viewData.world,
              mathNotation: viewData.mathNotation,
              onResize: onResize,
              onTick: onTick,
              canAccept: canAccept,
              onStartDragging: onStartDragging,
              onSelectOperator: onSelectOperator,
              onPlaceSelected: onPlaceSelected,
              selectedOperatorId: viewData.selectedOperatorId,
              onCancelDragging: onCancelDragging,
              onDrop: onDrop,
              onRestart: onRestart,
            ),
          ),
        ],
      ),
    ),
  );
}

class _OperatorConveyorPlayArea extends StatefulWidget {
  final ConveyorState initialState;
  final OperatorConveyorWorld world;
  final MathNotation mathNotation;
  final void Function(double width, double height) onResize;
  final ConveyorState Function(double) onTick;
  final bool Function({required int operatorId, required int shelfId})
  canAccept;
  final ValueChanged<int> onStartDragging;
  final ValueChanged<int> onSelectOperator;
  final ValueChanged<int> onPlaceSelected;
  final int? selectedOperatorId;
  final ValueChanged<int> onCancelDragging;
  final void Function({required int operatorId, required int shelfId}) onDrop;
  final VoidCallback onRestart;

  const _OperatorConveyorPlayArea({
    required this.initialState,
    required this.world,
    required this.mathNotation,
    required this.onResize,
    required this.onTick,
    required this.canAccept,
    required this.onStartDragging,
    required this.onSelectOperator,
    required this.onPlaceSelected,
    required this.selectedOperatorId,
    required this.onCancelDragging,
    required this.onDrop,
    required this.onRestart,
  });

  @override
  State<_OperatorConveyorPlayArea> createState() =>
      _OperatorConveyorPlayAreaState();
}

class _OperatorConveyorPlayAreaState extends State<_OperatorConveyorPlayArea> {
  late ConveyorState _state = widget.initialState;
  final ValueNotifier<int> _frame = ValueNotifier(0);
  late final ConveyorGame _game = ConveyorGame(
    gameWorld: widget.world,
    onResize: widget.onResize,
    onTick: widget.onTick,
    onFrame: _refreshFrame,
  );
  bool _frameRefreshScheduled = false;

  void _refreshFrame(ConveyorState state) {
    if (!mounted) return;
    _state = state;

    if (_frameRefreshScheduled) return;
    _frameRefreshScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _frameRefreshScheduled = false;
      if (mounted) _frame.value++;
    });
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
                  builder: (_, _) => _MovingOperatorPieces(
                    world: widget.world,
                    mathNotation: widget.mathNotation,
                    canAccept: widget.canAccept,
                    onStartDragging: widget.onStartDragging,
                    onSelectOperator: widget.onSelectOperator,
                    onPlaceSelected: widget.onPlaceSelected,
                    selectedOperatorId: widget.selectedOperatorId,
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

class _MovingOperatorPieces extends StatelessWidget {
  final OperatorConveyorWorld world;
  final MathNotation mathNotation;
  final bool Function({required int operatorId, required int shelfId})
  canAccept;
  final ValueChanged<int> onStartDragging;
  final ValueChanged<int> onSelectOperator;
  final ValueChanged<int> onPlaceSelected;
  final int? selectedOperatorId;
  final ValueChanged<int> onCancelDragging;
  final void Function({required int operatorId, required int shelfId}) onDrop;

  const _MovingOperatorPieces({
    required this.world,
    required this.mathNotation,
    required this.canAccept,
    required this.onStartDragging,
    required this.onSelectOperator,
    required this.onPlaceSelected,
    required this.selectedOperatorId,
    required this.onCancelDragging,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.hardEdge,
    children: [
      for (final shelf in world.shelves)
        Positioned(
          key: ValueKey('operator-shelf-${shelf.id}'),
          left: world.leftBeltX + 5,
          top: shelf.y,
          width: world.leftBeltWidth - 10,
          height: world.config.shelfHeight,
          child: DragTarget<int>(
            onWillAcceptWithDetails: (details) =>
                canAccept(operatorId: details.data, shelfId: shelf.id),
            onAcceptWithDetails: (details) =>
                onDrop(operatorId: details.data, shelfId: shelf.id),
            builder: (_, candidates, _) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: selectedOperatorId == null
                  ? null
                  : () => onPlaceSelected(shelf.id),
              child: _EquationCard(
                shelf: shelf,
                mathNotation: mathNotation,
                isHovering: candidates.isNotEmpty,
              ),
            ),
          ),
        ),
      for (final tile in world.operators)
        Positioned(
          key: ValueKey('operator-${tile.id}'),
          left:
              world.rightBeltX +
              (world.config.rightBeltWidth - world.config.letterSize) / 2,
          top: tile.y,
          width: world.config.letterSize,
          height: world.config.letterSize,
          child: Draggable<int>(
            data: tile.id,
            onDragStarted: () => onStartDragging(tile.id),
            onDraggableCanceled: (_, _) => onCancelDragging(tile.id),
            onDragEnd: (details) {
              if (!details.wasAccepted) onCancelDragging(tile.id);
            },
            feedback: Material(
              color: Colors.transparent,
              child: SizedBox.square(
                dimension: world.config.letterSize,
                child: _OperatorCard(
                  symbol: mathNotation.arithmeticOperatorSymbol(tile.operator),
                ),
              ),
            ),
            childWhenDragging: const SizedBox.shrink(),
            child: GestureDetector(
              onTap: () => onSelectOperator(tile.id),
              child: _OperatorCard(
                symbol: mathNotation.arithmeticOperatorSymbol(tile.operator),
                isSelected: selectedOperatorId == tile.id,
              ),
            ),
          ),
        ),
    ],
  );
}

class _EquationCard extends StatelessWidget {
  final OperatorConveyorShelf shelf;
  final MathNotation mathNotation;
  final bool isHovering;
  const _EquationCard({
    required this.shelf,
    required this.mathNotation,
    required this.isHovering,
  });

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
      padding: const EdgeInsets.all(10),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          shelf.isComplete
              ? '${shelf.equation.left}  ${mathNotation.arithmeticOperatorSymbol(shelf.placedOperator!)}  ${shelf.equation.right} = ${shelf.equation.result}'
              : shelf.equation.display,
          maxLines: 1,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: shelf.isComplete ? const Color(0xff81c784) : Colors.white,
          ),
        ),
      ),
    ),
  );
}

class _OperatorCard extends StatelessWidget {
  final String symbol;
  final bool isSelected;
  const _OperatorCard({required this.symbol, this.isSelected = false});

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
        symbol,
        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
