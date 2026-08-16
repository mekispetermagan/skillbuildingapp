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
            (context.l10n.mathFeature(number), onPressed),
        ],
      ),
    ),
  );
}
