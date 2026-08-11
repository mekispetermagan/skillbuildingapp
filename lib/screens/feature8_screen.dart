import 'package:flutter/material.dart';

import 'placeholder_feature_screen.dart';

class Feature8Screen extends StatelessWidget {
  final VoidCallback onBack;

  const Feature8Screen({required this.onBack, super.key});

  @override
  Widget build(BuildContext context) =>
      PlaceholderFeatureScreen(title: 'Feature 8', onBack: onBack);
}
