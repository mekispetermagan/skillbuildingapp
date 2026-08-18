import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

class OpeningScreen extends StatelessWidget {
  final VoidCallback onStart;

  const OpeningScreen({required this.onStart, super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: FilledButton(
            onPressed: onStart,
            child: Text(context.l10n.start),
          ),
        ),
      ],
    ),
  );
}
