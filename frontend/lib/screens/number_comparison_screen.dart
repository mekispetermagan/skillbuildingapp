import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/number_comparison.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/reward_gem_row.dart';
import '../widgets/single_select_segments.dart';

class NumberComparisonScreen extends StatelessWidget {
  final NumberComparisonViewData viewData;
  final VoidCallback onBack;
  final ValueChanged<ComparisonRange> onSetRange;
  final ValueChanged<NumberArrangement> onSetArrangement;
  final ValueChanged<NumberRelation> onGuess;

  const NumberComparisonScreen({
    required this.viewData,
    required this.onBack,
    required this.onSetRange,
    required this.onSetArrangement,
    required this.onGuess,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(
      title: context.l10n.activityNumberComparison,
      onBack: onBack,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                SingleSelectSegments<ComparisonRange>(
                  choices: const [
                    SegmentChoice(
                      value: ComparisonRange.oneToSix,
                      label: '1–6',
                    ),
                    SegmentChoice(
                      value: ComparisonRange.oneToTwelve,
                      label: '1–12',
                    ),
                  ],
                  selected: viewData.range,
                  onSelected: onSetRange,
                ),
                SingleSelectSegments<NumberArrangement>(
                  choices: [
                    SegmentChoice(
                      value: NumberArrangement.pattern,
                      label: context.l10n.numberPattern,
                    ),
                    SegmentChoice(
                      value: NumberArrangement.scattered,
                      label: context.l10n.numberScattered,
                    ),
                  ],
                  selected: viewData.arrangement,
                  onSelected: onSetArrangement,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 360,
              child: Row(
                children: [
                  Expanded(
                    child: _QuantityDisplay(
                      number: viewData.leftNumber,
                      emoji: viewData.leftEmoji,
                      arrangement: viewData.arrangement,
                      positions: viewData.leftPositions,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final relation in NumberRelation.values)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: SizedBox.square(
                              dimension: 58,
                              child: FilledButton(
                                key: ValueKey(
                                  'number-relation-${relation.name}',
                                ),
                                onPressed: viewData.canGuess
                                    ? () => onGuess(relation)
                                    : null,
                                style: FilledButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  _symbol(relation),
                                  style: const TextStyle(fontSize: 32),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _QuantityDisplay(
                      number: viewData.rightNumber,
                      emoji: viewData.rightEmoji,
                      arrangement: viewData.arrangement,
                      positions: viewData.rightPositions,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            RewardGemRow(count: viewData.score),
          ],
        ),
      ),
    ),
  );
}

String _symbol(NumberRelation relation) => switch (relation) {
  NumberRelation.lessThan => '<',
  NumberRelation.equal => '=',
  NumberRelation.greaterThan => '>',
};

class _QuantityDisplay extends StatelessWidget {
  final int number;
  final String emoji;
  final NumberArrangement arrangement;
  final List<(double, double)> positions;

  const _QuantityDisplay({
    required this.number,
    required this.emoji,
    required this.arrangement,
    required this.positions,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(
        color: Theme.of(context).colorScheme.outline,
        width: 4,
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: arrangement == NumberArrangement.pattern
          ? _VerticalPattern(number: number, emoji: emoji)
          : _ScatteredPattern(emoji: emoji, positions: positions),
    ),
  );
}

class _VerticalPattern extends StatelessWidget {
  final int number;
  final String emoji;
  const _VerticalPattern({required this.number, required this.emoji});

  @override
  Widget build(BuildContext context) {
    final isDouble = number > 6;
    if (!isDouble) {
      return Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: _DiePattern(count: number, emoji: emoji),
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: _DiePattern(count: 6, emoji: emoji)),
        const Divider(height: 12, thickness: 2),
        Expanded(
          child: _DiePattern(count: number - 6, emoji: emoji),
        ),
      ],
    );
  }
}

class _ScatteredPattern extends StatelessWidget {
  final String emoji;
  final List<(double, double)> positions;
  const _ScatteredPattern({required this.emoji, required this.positions});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = 3;
      final rows = 6;
      final cellWidth = constraints.maxWidth / columns;
      final cellHeight = constraints.maxHeight / rows;
      final emojiSize = math.min(cellWidth, cellHeight);
      return Stack(
        children: [
          for (final position in positions)
            Align(
              alignment: Alignment(position.$1, position.$2),
              child: SizedBox.square(
                dimension: emojiSize,
                child: FittedBox(child: Text(emoji)),
              ),
            ),
        ],
      );
    },
  );
}

class _DiePattern extends StatelessWidget {
  final int count;
  final String emoji;
  const _DiePattern({required this.count, required this.emoji});

  static const _positions = {
    1: [Alignment.center],
    2: [Alignment.topRight, Alignment.bottomLeft],
    3: [Alignment.topRight, Alignment.center, Alignment.bottomLeft],
    4: [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ],
    5: [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.center,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ],
    6: [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.centerLeft,
      Alignment.centerRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ],
  };

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      for (final alignment in _positions[count]!)
        Align(
          alignment: alignment,
          child: FittedBox(
            child: Text(emoji, style: const TextStyle(fontSize: 40)),
          ),
        ),
    ],
  );
}
