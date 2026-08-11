import 'package:flutter/material.dart';

import '../controllers/countdown_controller.dart';
import '../models/letter_dragging_state.dart';
import '../models/letter_dragging_tile.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/letter_dragging_card.dart';
import '../widgets/letter_dragging_countdown.dart';
import '../widgets/letter_dragging_rewards.dart';

class LetterDraggingScreen extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<LetterDraggingTile> tiles;
  final LetterDraggingState state;
  final int score;
  final CountdownController? countdown;
  final VoidCallback onBack;
  final void Function(int, int)? onReorder;
  final VoidCallback? onPass;

  const LetterDraggingScreen({
    required this.isLoading,
    required this.errorMessage,
    required this.tiles,
    required this.state,
    required this.score,
    required this.countdown,
    required this.onBack,
    required this.onReorder,
    required this.onPass,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FeatureAppBar(title: 'Letter dragging', onBack: onBack),
      body: switch ((isLoading, errorMessage, countdown)) {
        (true, _, _) => const Center(child: CircularProgressIndicator()),
        (_, final String message, _) => Center(child: Text(message)),
        (_, _, final CountdownController countdown) => _buildExercise(
          countdown,
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildExercise(CountdownController countdownController) {
    final reorder = onReorder;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Spacer(),
            const Text(
              'Put the letters in the right order',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 60,
              child: ReorderableListView(
                buildDefaultDragHandles: false,
                scrollDirection: Axis.horizontal,
                onReorderItem: reorder ?? (_, _) {},
                proxyDecorator: (child, _, animation) => Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(16),
                  child: child,
                ),
                children: [
                  for (final (index, tile) in tiles.indexed)
                    LetterDraggingCard(
                      key: ValueKey(tile.id),
                      tile: tile,
                      index: index,
                      state: state,
                      canDrag: reorder != null,
                    ),
                ],
              ),
            ),
            const Spacer(),
            FilledButton(onPressed: onPass, child: const Text('Pass')),
            const SizedBox(height: 20),
            LetterDraggingCountdown(controller: countdownController),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 34),
              child: LetterDraggingRewards(count: score),
            ),
          ],
        ),
      ),
    );
  }
}
