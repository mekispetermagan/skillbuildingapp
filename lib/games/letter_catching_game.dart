import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/painting.dart';

import '../controllers/letter_catching_controller.dart';
import '../models/letter_catching_world.dart';

class LetterCatchingGame extends FlameGame {
  final LetterCatchingController controller;

  LetterCatchingGame(this.controller);

  @override
  Color backgroundColor() => const Color(0xff101318);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    controller.resize(size.x, size.y);
  }

  @override
  void update(double dt) {
    controller.tick(dt);
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final world = controller.world;
    _renderTargetWord(canvas, world);
    _renderFallingLetters(canvas, world);
    _renderPaddle(canvas, world);
  }

  void _renderTargetWord(Canvas canvas, LetterCatchingWorld world) {
    const letterSize = 40.0;
    const gap = 5.0;
    final wordWidth =
        world.currentWord.word.length * letterSize +
        (world.currentWord.word.length - 1) * gap;
    final startX = (world.width - wordWidth) / 2;
    final top = max(130.0, world.height * 0.36);
    for (var index = 0; index < world.currentWord.word.length; index++) {
      final bounds = Rect.fromLTWH(
        startX + index * (letterSize + gap),
        top,
        letterSize,
        letterSize,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bounds, const Radius.circular(8)),
        Paint()
          ..color = world.matchedLetters[index]
              ? const Color(0xff2e7d32)
              : const Color(0xff3b4048),
      );
      _paintCenteredText(
        canvas,
        world.currentWord.word[index],
        bounds,
        color: world.matchedLetters[index]
            ? Colors.white
            : const Color(0xff8b9199),
        fontSize: 24,
      );
    }
  }

  void _renderFallingLetters(Canvas canvas, LetterCatchingWorld world) {
    final size = world.config.fallingLetterSize;
    for (final falling in world.fallingLetters) {
      final bounds = Rect.fromLTWH(falling.x, falling.y, size, size);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bounds, const Radius.circular(9)),
        Paint()..color = const Color(0xff5e35b1),
      );
      _paintCenteredText(canvas, falling.letter, bounds, fontSize: 22);
    }
  }

  void _renderPaddle(Canvas canvas, LetterCatchingWorld world) {
    final bounds = Rect.fromLTWH(
      world.paddleX,
      world.paddleY,
      world.config.paddleWidth,
      world.config.paddleHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(10)),
      Paint()..color = const Color(0xffffd54f),
    );
  }

  void _paintCenteredText(
    Canvas canvas,
    String text,
    Rect bounds, {
    Color color = Colors.white,
    double fontSize = 20,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        bounds.center.dx - painter.width / 2,
        bounds.center.dy - painter.height / 2,
      ),
    );
  }
}
