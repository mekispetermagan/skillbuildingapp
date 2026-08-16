import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../widgets/feature_app_bar.dart';

class MathPlaceholderScreen extends StatelessWidget {
  final int featureNumber;
  final VoidCallback onBack;

  const MathPlaceholderScreen({
    required this.featureNumber,
    required this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(
      title: context.l10n.mathFeature(featureNumber),
      onBack: onBack,
    ),
    body: SafeArea(
      child: Center(
        child: Text(
          context.l10n.featureComingSoon,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    ),
  );
}
