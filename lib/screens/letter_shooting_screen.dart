import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../games/letter_shooting_game.dart';
import '../models/letter_shooting_world.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/feature_load_state.dart';
import '../widgets/game_end_overlay.dart';
import '../widgets/reward_row.dart';

class LetterShootingScreen extends StatelessWidget {
  final LetterShootingViewData viewData;
  final void Function(double width, double height) onResize;
  final ValueChanged<double> onTick;
  final ValueChanged<GamePoint> onTap;
  final ValueChanged<GamePoint> onBeginAim;
  final ValueChanged<GamePoint> onUpdateAim;
  final VoidCallback onReleaseAim;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  const LetterShootingScreen({
    required this.viewData,
    required this.onResize,
    required this.onTick,
    required this.onTap,
    required this.onBeginAim,
    required this.onUpdateAim,
    required this.onReleaseAim,
    required this.onBack,
    required this.onRestart,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FeatureAppBar(title: 'Letter shooting', onBack: onBack),
      body: FeatureLoadState(
        isLoading: viewData.isLoading,
        errorMessage: viewData.errorMessage,
        child: switch (viewData.world) {
          final LetterShootingWorld world => SafeArea(
            child: _LetterShootingPlayArea(
              world: world,
              state: viewData.state,
              onResize: onResize,
              onTick: onTick,
              onTap: onTap,
              onBeginAim: onBeginAim,
              onUpdateAim: onUpdateAim,
              onReleaseAim: onReleaseAim,
              onRestart: onRestart,
            ),
          ),
          null => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _LetterShootingPlayArea extends StatefulWidget {
  final LetterShootingWorld world;
  final LetterShootingState state;
  final void Function(double width, double height) onResize;
  final ValueChanged<double> onTick;
  final ValueChanged<GamePoint> onTap;
  final ValueChanged<GamePoint> onBeginAim;
  final ValueChanged<GamePoint> onUpdateAim;
  final VoidCallback onReleaseAim;
  final VoidCallback onRestart;

  const _LetterShootingPlayArea({
    required this.world,
    required this.state,
    required this.onResize,
    required this.onTick,
    required this.onTap,
    required this.onBeginAim,
    required this.onUpdateAim,
    required this.onReleaseAim,
    required this.onRestart,
  });

  @override
  State<_LetterShootingPlayArea> createState() =>
      _LetterShootingPlayAreaState();
}

class _LetterShootingPlayAreaState extends State<_LetterShootingPlayArea> {
  late final LetterShootingGame _game = LetterShootingGame(
    gameWorld: widget.world,
    onResize: widget.onResize,
    onTick: widget.onTick,
  );

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
                  onTapUp: (details) => widget.onTap(
                    GamePoint(
                      details.localPosition.dx,
                      details.localPosition.dy,
                    ),
                  ),
                  onPanStart: (details) => widget.onBeginAim(
                    GamePoint(
                      details.localPosition.dx,
                      details.localPosition.dy,
                    ),
                  ),
                  onPanUpdate: (details) => widget.onUpdateAim(
                    GamePoint(
                      details.localPosition.dx,
                      details.localPosition.dy,
                    ),
                  ),
                  onPanEnd: (_) => widget.onReleaseAim(),
                  onPanCancel: widget.onReleaseAim,
                  child: GameWidget(game: _game),
                ),
              ),
              if (widget.state == LetterShootingState.ended)
                Positioned.fill(
                  child: GameEndOverlay(onRestart: widget.onRestart),
                ),
            ],
          ),
        ),
        RewardRow(count: widget.world.score),
      ],
    );
  }
}
