import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../widgets/account_menu.dart';

class AreaMenuScreen extends StatelessWidget {
  final VoidCallback onOpenLiteracy;
  final VoidCallback onOpenMath;

  const AreaMenuScreen({
    required this.onOpenLiteracy,
    required this.onOpenMath,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(actions: const [AccountMenuButton()]),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _AreaButton(
                  label: context.l10n.areaLiteracy,
                  imagePath: 'assets/images/area_menu/literacy_menu.png',
                  onPressed: onOpenLiteracy,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _AreaButton(
                  label: context.l10n.areaMath,
                  imagePath: 'assets/images/area_menu/math_menu.png',
                  onPressed: onOpenMath,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AreaButton extends StatelessWidget {
  final String label;
  final String imagePath;
  final VoidCallback onPressed;

  const _AreaButton({
    required this.label,
    required this.imagePath,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: Column(
      children: [
        Expanded(child: Image.asset(imagePath, fit: BoxFit.contain)),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
        ),
      ],
    ),
  );
}
