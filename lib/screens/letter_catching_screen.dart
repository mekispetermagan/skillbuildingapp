import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../controllers/letter_catching_controller.dart';
import '../games/letter_catching_game.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/lives_display.dart';
import '../widgets/rewards.dart';

class LetterCatchingScreen extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final LetterCatchingController? controller;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  const LetterCatchingScreen({
    required this.isLoading,
    required this.errorMessage,
    required this.controller,
    required this.onBack,
    required this.onRestart,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(title: 'Letter catching', onBack: onBack),
    body: switch ((isLoading, errorMessage, controller)) {
      (true, _, _) => const Center(child: CircularProgressIndicator()),
      (_, final String message, _) => Center(child: Text(message)),
      (_, _, final LetterCatchingController controller) => SafeArea(
        child: _LetterCatchingPlayArea(
          controller: controller,
          onRestart: onRestart,
        ),
      ),
      _ => const SizedBox.shrink(),
    },
  );
}

class _LetterCatchingPlayArea extends StatefulWidget {
  final LetterCatchingController controller;
  final VoidCallback onRestart;

  const _LetterCatchingPlayArea({
    required this.controller,
    required this.onRestart,
  });

  @override
  State<_LetterCatchingPlayArea> createState() =>
      _LetterCatchingPlayAreaState();
}

class _LetterCatchingPlayAreaState extends State<_LetterCatchingPlayArea> {
  late final LetterCatchingGame _game = LetterCatchingGame(widget.controller);

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
                    widget.controller.movePaddleBy(details.delta.dx),
                child: GameWidget(game: _game),
              ),
            ),
            Positioned(
              top: 10,
              right: 12,
              child: IgnorePointer(
                child: ListenableBuilder(
                  listenable: widget.controller,
                  builder: (_, _) => LivesDisplay(
                    lives: widget.controller.world.lives,
                    maximumLives: widget.controller.world.config.startingLives,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: ListenableBuilder(
                listenable: widget.controller,
                builder: (_, _) => switch (widget.controller.state) {
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
            ),
          ],
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
