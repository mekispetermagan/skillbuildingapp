import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/activity_id.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/feature_menu_grid.dart';

class LiteracyMenuScreen extends StatelessWidget {
  final List<(ActivityId, VoidCallback)> menuItems;
  final VoidCallback onBack;

  const LiteracyMenuScreen({
    required this.menuItems,
    required this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(title: context.l10n.areaLiteracy, onBack: onBack),
    body: SafeArea(
      child: FeatureMenuGrid(
        items: [
          for (final (activity, onPressed) in menuItems)
            (activity.label(context.l10n), onPressed),
        ],
      ),
    ),
  );
}
