import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../controllers/letter_shooting_controller.dart';
import '../games/letter_shooting_game.dart';
import '../models/letter_shooting_world.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/rewards.dart';

class LetterShootingScreen extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final LetterShootingController? controller;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  const LetterShootingScreen({
    required this.isLoading,
    required this.errorMessage,
    required this.controller,
    required this.onBack,
    required this.onRestart,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FeatureAppBar(title: 'Letter shooting', onBack: onBack),
      body: switch ((isLoading, errorMessage, controller)) {
        (true, _, _) => const Center(child: CircularProgressIndicator()),
        (_, final String message, _) => Center(child: Text(message)),
        (_, _, final LetterShootingController controller) => SafeArea(
          child: _LetterShootingPlayArea(
            controller: controller,
            onRestart: onRestart,
          ),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _LetterShootingPlayArea extends StatefulWidget {
  final LetterShootingController controller;
  final VoidCallback onRestart;

  const _LetterShootingPlayArea({
    required this.controller,
    required this.onRestart,
  });

  @override
  State<_LetterShootingPlayArea> createState() =>
      _LetterShootingPlayAreaState();
}

class _LetterShootingPlayAreaState extends State<_LetterShootingPlayArea> {
  late final LetterShootingGame _game = LetterShootingGame(widget.controller);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => widget.controller.tap(
                    GamePoint(
                      details.localPosition.dx,
                      details.localPosition.dy,
                    ),
                  ),
                  onPanStart: (details) => widget.controller.beginAim(
                    GamePoint(
                      details.localPosition.dx,
                      details.localPosition.dy,
                    ),
                  ),
                  onPanUpdate: (details) => widget.controller.updateAim(
                    GamePoint(
                      details.localPosition.dx,
                      details.localPosition.dy,
                    ),
                  ),
                  onPanEnd: (_) => widget.controller.releaseAim(),
                  onPanCancel: widget.controller.releaseAim,
                  child: GameWidget(game: _game),
                ),
              ),
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: widget.controller,
                  builder: (_, _) =>
                      widget.controller.state == LetterShootingState.ended
                      ? ColoredBox(
                          color: Colors.black54,
                          child: Center(
                            child: FilledButton(
                              onPressed: widget.onRestart,
                              child: const Text('Play again?'),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
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
}
