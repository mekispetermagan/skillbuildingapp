import 'package:flutter/material.dart';

import '../widgets/feature_app_bar.dart';

class PlaceholderFeatureScreen extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const PlaceholderFeatureScreen({
    required this.title,
    required this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FeatureAppBar(title: title, onBack: onBack),
      body: Center(child: Text('$title is coming soon.')),
    );
  }
}
