import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../games/letter_catching_game.dart';
import '../models/letter_catching_world.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/lives_display.dart';
import '../widgets/rewards.dart';

class LetterCatchingScreen extends StatelessWidget {
  final LetterCatchingViewData viewData;
  final void Function(double width, double height) onResize;
  final ValueChanged<double> onTick;
  final ValueChanged<double> onMovePaddleBy;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  const LetterCatchingScreen({
    required this.viewData,
    required this.onResize,
    required this.onTick,
    required this.onMovePaddleBy,
    required this.onBack,
    required this.onRestart,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(title: 'Letter catching', onBack: onBack),
    body: switch ((viewData.isLoading, viewData.errorMessage, viewData.world)) {
      (true, _, _) => const Center(child: CircularProgressIndicator()),
      (_, final String message, _) => Center(child: Text(message)),
      (_, _, final LetterCatchingWorld world) => SafeArea(
        child: _LetterCatchingPlayArea(
          world: world,
          state: viewData.state,
          onResize: onResize,
          onTick: onTick,
          onMovePaddleBy: onMovePaddleBy,
          onRestart: onRestart,
        ),
      ),
      _ => const SizedBox.shrink(),
    },
  );
}

class _LetterCatchingPlayArea extends StatefulWidget {
  final LetterCatchingWorld world;
  final LetterCatchingState state;
  final void Function(double width, double height) onResize;
  final ValueChanged<double> onTick;
  final ValueChanged<double> onMovePaddleBy;
  final VoidCallback onRestart;

  const _LetterCatchingPlayArea({
    required this.world,
    required this.state,
    required this.onResize,
    required this.onTick,
    required this.onMovePaddleBy,
    required this.onRestart,
  });

  @override
  State<_LetterCatchingPlayArea> createState() =>
      _LetterCatchingPlayAreaState();
}

class _LetterCatchingPlayAreaState extends State<_LetterCatchingPlayArea> {
  late final LetterCatchingGame _game = LetterCatchingGame(
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
                LetterCatchingState.won => _EndOverlay(
                  message: 'Congratulations!',
                  onRestart: widget.onRestart,
                ),
                LetterCatchingState.lost => _EndOverlay(
                  message: 'Sorry!',
                  onRestart: widget.onRestart,
                ),
              },
            ),
          ],
        ),
      ),
      SizedBox(height: 46, child: Rewards(count: widget.world.score)),
    ],
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
