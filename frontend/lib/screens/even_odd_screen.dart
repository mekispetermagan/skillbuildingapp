import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../games/even_odd_game.dart';
import '../l10n/l10n.dart';
import '../models/even_odd_world.dart';
import '../models/letter_catching_state.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/game_end_overlay.dart';
import '../widgets/lives_display.dart';
import '../widgets/reward_gem_row.dart';

class EvenOddScreen extends StatelessWidget {
  final EvenOddViewData viewData;
  final void Function(double width, double height) onResize;
  final ValueChanged<double> onTick;
  final ValueChanged<double> onMovePaddleBy;
  final VoidCallback onToggleParity;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  const EvenOddScreen({
    required this.viewData,
    required this.onResize,
    required this.onTick,
    required this.onMovePaddleBy,
    required this.onToggleParity,
    required this.onBack,
    required this.onRestart,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(title: context.l10n.activityEvenOdd, onBack: onBack),
    body: SafeArea(
      child: _EvenOddPlayArea(
        world: viewData.world,
        state: viewData.state,
        onResize: onResize,
        onTick: onTick,
        onMovePaddleBy: onMovePaddleBy,
        onToggleParity: onToggleParity,
        onRestart: onRestart,
      ),
    ),
  );
}

class _EvenOddPlayArea extends StatefulWidget {
  final EvenOddWorld world;
  final LetterCatchingState state;
  final void Function(double width, double height) onResize;
  final ValueChanged<double> onTick;
  final ValueChanged<double> onMovePaddleBy;
  final VoidCallback onToggleParity;
  final VoidCallback onRestart;

  const _EvenOddPlayArea({
    required this.world,
    required this.state,
    required this.onResize,
    required this.onTick,
    required this.onMovePaddleBy,
    required this.onToggleParity,
    required this.onRestart,
  });

  @override
  State<_EvenOddPlayArea> createState() => _EvenOddPlayAreaState();
}

class _EvenOddPlayAreaState extends State<_EvenOddPlayArea> {
  late final EvenOddGame _game = EvenOddGame(
    gameWorld: widget.world,
    onResize: widget.onResize,
    onTick: widget.onTick,
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onToggleParity,
                onHorizontalDragUpdate: (details) =>
                    widget.onMovePaddleBy(details.delta.dx),
                child: GameWidget(game: _game),
              ),
            ),
            Positioned(
              top: 10,
              right: 12,
              child: IgnorePointer(
                child: LivesDisplay(
                  lives: widget.world.lives,
                  maximumLives: widget.world.config.startingLives,
                ),
              ),
            ),
            Positioned.fill(
              child: switch (widget.state) {
                LetterCatchingState.playing => const SizedBox.shrink(),
                LetterCatchingState.won => GameEndOverlay(
                  message: context.l10n.congratulations,
                  onRestart: widget.onRestart,
                ),
                LetterCatchingState.lost => GameEndOverlay(
                  message: context.l10n.sorry,
                  onRestart: widget.onRestart,
                ),
              },
            ),
          ],
        ),
      ),
      RewardGemRow(count: widget.world.score),
    ],
  );
}
