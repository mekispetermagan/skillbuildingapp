import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

class GameEndOverlay extends StatelessWidget {
  final String? message;
  final VoidCallback onRestart;
  final String? restartLabel;

  const GameEndOverlay({
    required this.onRestart,
    this.message,
    this.restartLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black54,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message case final message?) ...[
            Text(message, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
          ],
          FilledButton(
            onPressed: onRestart,
            child: Text(restartLabel ?? context.l10n.playAgain),
          ),
        ],
      ),
    ),
  );
}
