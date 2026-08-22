import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/operations_practice.dart';
import '../models/view_data.dart';
import '../theme/number_palette.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/reward_gem_row.dart';
import '../widgets/single_select_segments.dart';

class OperationsPracticeScreen extends StatelessWidget {
  final OperationsPracticeViewData viewData;
  final VoidCallback onBack;
  final ValueChanged<Set<ElementaryOperator>> onSetOperators;
  final ValueChanged<OperationsRange> onSetRange;
  final ValueChanged<bool> onSetUseColors;
  final ValueChanged<int> onGuess;

  const OperationsPracticeScreen({
    required this.viewData,
    required this.onBack,
    required this.onSetOperators,
    required this.onSetRange,
    required this.onSetUseColors,
    required this.onGuess,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(
      title: context.l10n.activityOperationsPractice,
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
                SegmentedButton<ElementaryOperator>(
                  segments: [
                    for (final operator in ElementaryOperator.values)
                      ButtonSegment(
                        value: operator,
                        label: Text(
                          viewData.mathNotation.elementaryOperatorSymbol(
                            operator,
                          ),
                        ),
                      ),
                  ],
                  selected: viewData.operators,
                  multiSelectionEnabled: true,
                  emptySelectionAllowed: false,
                  showSelectedIcon: false,
                  onSelectionChanged: onSetOperators,
                ),
                SingleSelectSegments<OperationsRange>(
                  choices: const [
                    SegmentChoice(
                      value: OperationsRange.oneToTwelve,
                      label: '1–12',
                    ),
                    SegmentChoice(
                      value: OperationsRange.oneToTwentyFour,
                      label: '1–24',
                    ),
                  ],
                  selected: viewData.range,
                  onSelected: onSetRange,
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
            const SizedBox(height: 36),
            _EquationDisplay(viewData: viewData),
            const SizedBox(height: 36),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final number in viewData.choices)
                  SizedBox.square(
                    dimension: 64,
                    child: FilledButton(
                      key: ValueKey('operations-practice-choice-$number'),
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
                        style: const TextStyle(fontSize: 26),
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

class _EquationDisplay extends StatelessWidget {
  final OperationsPracticeViewData viewData;

  const _EquationDisplay({required this.viewData});

  @override
  Widget build(BuildContext context) {
    final equation = viewData.equation;
    final style = Theme.of(
      context,
    ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold);
    return Semantics(
      label:
          '${equation.left} ${viewData.mathNotation.elementaryOperatorSymbol(equation.operator)} '
          '${equation.right} = ?',
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        children: [
          Text('${equation.left}', style: style),
          Text(
            viewData.mathNotation.elementaryOperatorSymbol(equation.operator),
            style: style,
          ),
          Text('${equation.right}', style: style),
          Text('=', style: style),
          Text(
            viewData.state == OperationsPracticeState.correct
                ? '${equation.answer}'
                : '?',
            style: style?.copyWith(
              color: viewData.useColors
                  ? numberColor(equation.answer)
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
