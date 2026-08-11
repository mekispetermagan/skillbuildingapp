import 'package:flutter/material.dart';

import '../models/countdown_status.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/feature_load_state.dart';
import '../widgets/letter_dragging_card.dart';
import '../widgets/letter_dragging_countdown.dart';
import '../widgets/reward_row.dart';

class LetterDraggingScreen extends StatelessWidget {
  final LetterDraggingViewData viewData;
  final VoidCallback onBack;
  final void Function(int, int)? onReorder;
  final VoidCallback? onPass;

  const LetterDraggingScreen({
    required this.viewData,
    required this.onBack,
    required this.onReorder,
    required this.onPass,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FeatureAppBar(title: 'Letter dragging', onBack: onBack),
      body: FeatureLoadState(
        isLoading: viewData.isLoading,
        errorMessage: viewData.errorMessage,
        child: switch (viewData.countdown) {
          final CountdownStatus countdown => _buildExercise(countdown),
          null => const SizedBox.shrink(),
        },
      ),
    );
  }

  Widget _buildExercise(CountdownStatus countdown) {
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
                  for (final (index, tile) in viewData.tiles.indexed)
                    LetterDraggingCard(
                      key: ValueKey(tile.id),
                      tile: tile,
                      index: index,
                      state: viewData.state,
                      canDrag: reorder != null,
                    ),
                ],
              ),
            ),
            const Spacer(),
            FilledButton(onPressed: onPass, child: const Text('Pass')),
            const SizedBox(height: 20),
            LetterDraggingCountdown(status: countdown),
            const SizedBox(height: 20),
            RewardRow(count: viewData.score),
          ],
        ),
      ),
    );
  }
}
