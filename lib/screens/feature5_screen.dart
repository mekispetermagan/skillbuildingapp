import 'package:flutter/material.dart';

import 'placeholder_feature_screen.dart';

class Feature5Screen extends StatelessWidget {
  final VoidCallback onBack;

  const Feature5Screen({required this.onBack, super.key});

  @override
  Widget build(BuildContext context) =>
      PlaceholderFeatureScreen(title: 'Feature 5', onBack: onBack);
}
