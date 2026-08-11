import 'package:flutter/material.dart';

import 'placeholder_feature_screen.dart';

class Feature7Screen extends StatelessWidget {
  final VoidCallback onBack;

  const Feature7Screen({required this.onBack, super.key});

  @override
  Widget build(BuildContext context) =>
      PlaceholderFeatureScreen(title: 'Feature 7', onBack: onBack);
}
