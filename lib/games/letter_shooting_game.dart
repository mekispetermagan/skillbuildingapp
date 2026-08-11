import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/painting.dart';

import '../controllers/letter_shooting_controller.dart';
import '../models/letter_shooting_world.dart';

class LetterShootingGame extends FlameGame {
  final LetterShootingController controller;

  LetterShootingGame(this.controller);

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
    _renderTargets(canvas, world);
    _renderProjectiles(canvas, world);
    _renderCannon(canvas, world);
    _renderSourceLetters(canvas, world);
  }

  void _renderTargets(Canvas canvas, LetterShootingWorld world) {
    final config = world.config;
    for (final target in world.targets) {
      final bounds = Rect.fromLTWH(
        target.x,
        target.y,
        config.targetWidth,
        config.targetHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bounds, const Radius.circular(12)),
        Paint()
          ..color = target.isSolved
              ? const Color(0xff2e7d32)
              : const Color(0xff314b68),
      );
      _paintCenteredText(canvas, target.displayWord, bounds, fontSize: 24);
    }
  }

  void _renderProjectiles(Canvas canvas, LetterShootingWorld world) {
    final radius = world.config.projectileSize / 2;
    for (final projectile in world.projectiles) {
      canvas.drawCircle(
        Offset(projectile.x, projectile.y),
        radius,
        Paint()..color = const Color(0xffffd54f),
      );
      _paintCenteredText(
        canvas,
        projectile.letter,
        Rect.fromCircle(
          center: Offset(projectile.x, projectile.y),
          radius: radius,
        ),
        color: const Color(0xff241a00),
        fontSize: 19,
      );
    }
  }

  void _renderCannon(Canvas canvas, LetterShootingWorld world) {
    final config = world.config;
    final pivot = world.cannonPivot;
    canvas.save();
    canvas.translate(pivot.x, pivot.y);
    canvas.rotate(world.cannonAngle);
    final cannon = Rect.fromLTWH(
      -config.cannonWidth / 2,
      -config.cannonHeight,
      config.cannonWidth,
      config.cannonHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cannon, const Radius.circular(8)),
      Paint()..color = const Color(0xff78909c),
    );
    final loadedLetter = world.loadedLetter;
    if (loadedLetter != null) {
      _paintCenteredText(
        canvas,
        loadedLetter,
        cannon,
        color: const Color(0xff101318),
        fontSize: 24,
      );
    }
    canvas.restore();
    canvas.drawCircle(
      Offset(pivot.x, pivot.y),
      config.cannonWidth * 0.34,
      Paint()..color = const Color(0xff455a64),
    );
  }

  void _renderSourceLetters(Canvas canvas, LetterShootingWorld world) {
    final selected = world.loadedLetter;
    for (final source in world.sourceLetters) {
      final bounds = Rect.fromLTWH(
        source.bounds.left,
        source.bounds.top,
        source.bounds.width,
        source.bounds.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bounds, const Radius.circular(8)),
        Paint()
          ..color = source.letter == selected
              ? const Color(0xffffd54f)
              : const Color(0xff5e35b1),
      );
      _paintCenteredText(
        canvas,
        source.letter,
        bounds,
        color: source.letter == selected
            ? const Color(0xff241a00)
            : Colors.white,
        fontSize: 20,
      );
    }
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
      maxLines: 1,
    )..layout(maxWidth: bounds.width);
    painter.paint(
      canvas,
      Offset(
        bounds.center.dx - painter.width / 2,
        bounds.center.dy - painter.height / 2,
      ),
    );
  }
}
