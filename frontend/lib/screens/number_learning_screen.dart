import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/number_learning.dart';
import '../models/view_data.dart';
import '../theme/number_palette.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/reward_gem_row.dart';
import '../widgets/single_select_segments.dart';

class NumberLearningScreen extends StatelessWidget {
  final NumberLearningViewData viewData;
  final VoidCallback onBack;
  final ValueChanged<NumberRange> onSetRange;
  final ValueChanged<bool> onSetUseColors;
  final ValueChanged<int> onGuess;

  const NumberLearningScreen({
    required this.viewData,
    required this.onBack,
    required this.onSetRange,
    required this.onSetUseColors,
    required this.onGuess,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(
      title: context.l10n.activityNumberLearning,
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
                SegmentedButton<NumberRange>(
                  segments: const [
                    ButtonSegment(
                      value: NumberRange.oneToSix,
                      label: Text('1–6'),
                    ),
                    ButtonSegment(
                      value: NumberRange.sevenToTwelve,
                      label: Text('7–12'),
                    ),
                  ],
                  selected: {viewData.range},
                  showSelectedIcon: false,
                  onSelectionChanged: (values) => onSetRange(values.single),
                ),
                SingleSelectSegments<bool>(
                  choices: [
                    SegmentChoice(value: true, label: context.l10n.colorsOn),
                    SegmentChoice(value: false, label: context.l10n.colorsOff),
                  ],
                  selected: viewData.useColors,
                  onSelected: onSetUseColors,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _NumberPattern(
              number: viewData.target,
              emoji: viewData.emoji,
              frameColor: viewData.useColors
                  ? numberColor(viewData.target)
                  : Colors.grey.shade500,
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final number in viewData.choices)
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: FilledButton(
                      key: ValueKey('number-learning-choice-$number'),
                      onPressed: viewData.canGuess
                          ? () => onGuess(number)
                          : null,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: numberColor(number),
                        foregroundColor: numberForeground(number),
                        disabledBackgroundColor: numberColor(number),
                        disabledForegroundColor: numberForeground(number),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        '$number',
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            RewardGemRow(count: viewData.score),
          ],
        ),
      ),
    ),
  );
}

class _NumberPattern extends StatelessWidget {
  final int number;
  final String emoji;
  final Color frameColor;

  const _NumberPattern({
    required this.number,
    required this.emoji,
    required this.frameColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDouble = number > 6;
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth.clamp(0.0, 420.0);
          final partSize = availableWidth / 2;
          return SizedBox(
            width: isDouble ? availableWidth : partSize,
            height: partSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: frameColor, width: 10),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: _DiePattern(
                        count: isDouble ? 6 : number,
                        emoji: emoji,
                      ),
                    ),
                    if (isDouble) ...[
                      const VerticalDivider(width: 18, thickness: 2),
                      Expanded(
                        child: _DiePattern(count: number - 6, emoji: emoji),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
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
