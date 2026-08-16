import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

import '../models/countdown_status.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/feature_load_state.dart';
import '../widgets/letter_dragging_card.dart';
import '../widgets/letter_dragging_countdown.dart';
import '../widgets/image_visibility_segments.dart';
import '../widgets/reward_gem_row.dart';

class LetterDraggingScreen extends StatelessWidget {
  final LetterDraggingViewData viewData;
  final VoidCallback onBack;
  final void Function(int, int)? onReorder;
  final VoidCallback? onPass;
  final ValueChanged<bool> onShowImagesChanged;

  const LetterDraggingScreen({
    required this.viewData,
    required this.onBack,
    required this.onReorder,
    required this.onPass,
    required this.onShowImagesChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FeatureAppBar(
        title: context.l10n.activityLetterDragging,
        onBack: onBack,
      ),
      body: FeatureLoadState(
        isLoading: viewData.isLoading,
        loadError: viewData.loadError,
        child: switch (viewData.countdown) {
          final CountdownStatus countdown => _buildExercise(context, countdown),
          null => const SizedBox.shrink(),
        },
      ),
    );
  }

  Widget _buildExercise(BuildContext context, CountdownStatus countdown) {
    final reorder = onReorder;
    final imagePath = viewData.imagePath;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Spacer(),
            Text(
              context.l10n.instructionOrderLetters,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 16),
            ImageVisibilitySegments(
              showImages: viewData.showImages,
              onChanged: onShowImagesChanged,
            ),
            if (viewData.showImages && imagePath != null) ...[
              const SizedBox(height: 12),
              Image.asset(
                imagePath,
                width: 90,
                height: 90,
                fit: BoxFit.contain,
              ),
            ],
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
            FilledButton(onPressed: onPass, child: Text(context.l10n.pass)),
            const SizedBox(height: 20),
            LetterDraggingCountdown(status: countdown),
            const SizedBox(height: 20),
            RewardGemRow(count: viewData.score),
          ],
        ),
      ),
    );
  }
}
