import 'package:flutter/material.dart';

import 'menu_button.dart';

class FeatureMenuGrid extends StatelessWidget {
  final List<(String, VoidCallback)> items;

  const FeatureMenuGrid({required this.items, super.key});

  @override
  Widget build(BuildContext context) => GridView.count(
    padding: const EdgeInsets.all(24),
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    children: [
      for (final (label, onPressed) in items)
        MenuButton(text: label, onPressed: onPressed),
    ],
  );
}
