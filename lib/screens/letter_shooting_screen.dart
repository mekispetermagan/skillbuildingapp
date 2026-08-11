import 'package:flutter/material.dart';

import '../widgets/feature_app_bar.dart';

class LetterShootingScreen extends StatelessWidget {
  final VoidCallback onBack;

  const LetterShootingScreen({required this.onBack, super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(title: 'Letter shooting', onBack: onBack),
    body: Center(child: Text("Coming soon.")),
  );
}
