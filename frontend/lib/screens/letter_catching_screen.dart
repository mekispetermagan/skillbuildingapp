import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

import '../games/letter_catching_game.dart';
import '../models/letter_catching_world.dart';
import '../models/letter_catching_state.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/feature_load_state.dart';
import '../widgets/game_end_overlay.dart';
import '../widgets/lives_display.dart';
import '../widgets/reward_gem_row.dart';

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
    appBar: FeatureAppBar(
      title: context.l10n.activityLetterCatching,
      onBack: onBack,
    ),
    body: FeatureLoadState(
      isLoading: viewData.isLoading,
      loadError: viewData.loadError,
      child: switch (viewData.world) {
        final LetterCatchingWorld world => SafeArea(
          child: _LetterCatchingPlayArea(
            world: world,
            state: viewData.state,
            onResize: onResize,
            onTick: onTick,
            onMovePaddleBy: onMovePaddleBy,
            onRestart: onRestart,
          ),
        ),
        null => const SizedBox.shrink(),
      },
    ),
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
