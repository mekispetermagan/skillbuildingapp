import 'dart:math';

import 'package:flutter/material.dart';

import '../controllers/countdown_controller.dart';

class LetterDraggingCountdown extends StatelessWidget {
  final CountdownController controller;

  const LetterDraggingCountdown({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, _) {
        final status = controller.status;
        final scheme = Theme.of(context).colorScheme;
        final elapsedWithinSecond =
            (status.totalMilliseconds - status.remainingMilliseconds) % 1000;
        final progress = status.isRunning ? elapsedWithinSecond / 1000 : 1.0;
        final filling = status.remainingSeconds.isEven;
        final danger = status.isInDangerZone;
        final fill = danger ? scheme.errorContainer : scheme.secondaryContainer;
        final foreground = danger
            ? scheme.onErrorContainer
            : scheme.onSecondaryContainer;
        final first = filling ? scheme.surface : fill;
        final second = filling ? fill : scheme.surface;

        return SizedBox.square(
          dimension: 92,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: -status.remainingSeconds / 30 * pi,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 42,
                  color: first,
                  backgroundColor: second,
                ),
              ),
              Transform.rotate(
                angle: -status.remainingSeconds / 30 * pi,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 7,
                  color: foreground,
                  backgroundColor: scheme.surface,
                ),
              ),
              Text(
                '${status.remainingSeconds}',
                style: TextStyle(
                  color: foreground,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
