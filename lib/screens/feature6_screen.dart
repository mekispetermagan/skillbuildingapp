import 'package:flutter/material.dart';

import 'placeholder_feature_screen.dart';

class Feature6Screen extends StatelessWidget {
  final VoidCallback onBack;

  const Feature6Screen({required this.onBack, super.key});

  @override
  Widget build(BuildContext context) =>
      PlaceholderFeatureScreen(title: 'Feature 6', onBack: onBack);
}
