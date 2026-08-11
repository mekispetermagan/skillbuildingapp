import 'package:flutter/material.dart';

import '../widgets/menu_button.dart';

class MenuScreen extends StatelessWidget {
  final List<(String, VoidCallback)> menuItems;

  const MenuScreen({required this.menuItems, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GridView.count(
          padding: const EdgeInsets.all(24),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            for (final (text, onPressed) in menuItems)
              MenuButton(text: text, onPressed: onPressed),
          ],
        ),
      ),
    );
  }
}
