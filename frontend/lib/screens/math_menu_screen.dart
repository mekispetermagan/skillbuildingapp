import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/feature_menu_grid.dart';

class MathMenuScreen extends StatelessWidget {
  final List<(int, VoidCallback)> menuItems;
  final VoidCallback onBack;

  const MathMenuScreen({
    required this.menuItems,
    required this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(title: context.l10n.areaMath, onBack: onBack),
    body: SafeArea(
      child: FeatureMenuGrid(
        items: [
          for (final (number, onPressed) in menuItems)
            (
              number == 1
                  ? context.l10n.activityNumberLearning
                  : number == 2
                  ? context.l10n.activityNumberComparison
                  : number == 3
                  ? context.l10n.activityOperationsPractice
                  : number == 4
                  ? context.l10n.activityNumberDragging
                  : number == 8
                  ? context.l10n.activityOperatorConveyor
                  : number == 7
                  ? context.l10n.activityEvenOdd
                  : context.l10n.mathFeature(number),
              onPressed,
            ),
        ],
      ),
    ),
  );
}
