import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/letter_dragging_state.dart';
import '../models/number_dragging.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/letter_dragging_countdown.dart';
import '../widgets/reward_gem_row.dart';
import '../widgets/single_select_segments.dart';

class NumberDraggingScreen extends StatelessWidget {
  final NumberDraggingViewData viewData;
  final VoidCallback onBack;
  final void Function(int, int)? onReorder;
  final VoidCallback? onPass;
  final ValueChanged<NumberDraggingRange> onSetRange;

  const NumberDraggingScreen({
    required this.viewData,
    required this.onBack,
    required this.onReorder,
    required this.onPass,
    required this.onSetRange,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(
      title: context.l10n.activityNumberDragging,
      onBack: onBack,
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SingleSelectSegments<NumberDraggingRange>(
              choices: const [
                SegmentChoice(
                  value: NumberDraggingRange.oneToTwelve,
                  label: '1–12',
                ),
                SegmentChoice(
                  value: NumberDraggingRange.oneToTwentyFour,
                  label: '1–24',
                ),
                SegmentChoice(
                  value: NumberDraggingRange.oneToSixty,
                  label: '1–60',
                ),
              ],
              selected: viewData.range,
              onSelected: onSetRange,
            ),
            const Spacer(),
            Text(
              context.l10n.instructionOrderNumbers,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 68,
              child: ReorderableListView(
                buildDefaultDragHandles: false,
                scrollDirection: Axis.horizontal,
                onReorderItem: onReorder ?? (_, _) {},
                proxyDecorator: (child, _, animation) => Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(16),
                  child: child,
                ),
                children: [
                  for (final (index, tile) in viewData.tiles.indexed)
                    _NumberDraggingCard(
                      key: ValueKey(tile.id),
                      tile: tile,
                      index: index,
                      state: viewData.state,
                      canDrag: onReorder != null,
                    ),
                ],
              ),
            ),
            const Spacer(),
            FilledButton(onPressed: onPass, child: Text(context.l10n.pass)),
            const SizedBox(height: 20),
            LetterDraggingCountdown(status: viewData.countdown),
            const SizedBox(height: 20),
            RewardGemRow(count: viewData.score),
          ],
        ),
      ),
    ),
  );
}

class _NumberDraggingCard extends StatelessWidget {
  final NumberDraggingTile tile;
  final int index;
  final LetterDraggingState state;
  final bool canDrag;

  const _NumberDraggingCard({
    required this.tile,
    required this.index,
    required this.state,
    required this.canDrag,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final baseScheme = Theme.of(context).colorScheme;
    final scheme = state == LetterDraggingState.successFeedback
        ? ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: baseScheme.brightness,
          )
        : baseScheme;
    final card = Card(
      color: scheme.primaryContainer,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Text(
            '${tile.number}',
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
    return canDrag
        ? ReorderableDragStartListener(index: index, child: card)
        : card;
  }
}
