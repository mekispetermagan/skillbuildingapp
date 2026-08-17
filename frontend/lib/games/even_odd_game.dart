import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../models/even_odd_world.dart';
import '../theme/feature_palette.dart';

class EvenOddGame extends FlameGame {
  final EvenOddWorld gameWorld;
  final void Function(double width, double height) onResize;
  final void Function(double deltaSeconds) onTick;

  EvenOddGame({
    required this.gameWorld,
    required this.onResize,
    required this.onTick,
  });

  ColorScheme get _scheme => FeaturePalette.schemeForIndex(
    gameWorld.parity == NumberParity.even ? 1 : 4,
  );

  @override
  Color backgroundColor() => _scheme.primary;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    onResize(size.x, size.y);
  }

  @override
  void update(double dt) {
    onTick(dt);
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final scheme = _scheme;
    _renderFallingNumbers(canvas, scheme);
    _renderPaddle(canvas, scheme);
  }

  void _renderFallingNumbers(Canvas canvas, ColorScheme scheme) {
    final size = gameWorld.config.fallingNumberSize;
    for (final falling in gameWorld.fallingNumbers) {
      final bounds = Rect.fromLTWH(falling.x, falling.y, size, size);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bounds, const Radius.circular(9)),
        Paint()..color = scheme.surface,
      );
      _paintCenteredText(
        canvas,
        '${falling.number}',
        bounds,
        color: scheme.onSurface,
        fontSize: 22,
      );
    }
  }

  void _renderPaddle(Canvas canvas, ColorScheme scheme) {
    final bounds = Rect.fromLTWH(
      gameWorld.paddleX,
      gameWorld.paddleY,
      gameWorld.config.paddleWidth,
      gameWorld.config.paddleHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(10)),
      Paint()..color = scheme.onPrimary,
    );
    _paintCenteredText(
      canvas,
      gameWorld.parity == NumberParity.even ? 'EVEN' : 'ODD',
      bounds,
      color: scheme.primary,
      fontSize: 18,
    );
  }

  void _paintCenteredText(
    Canvas canvas,
    String text,
    Rect bounds, {
    required Color color,
    required double fontSize,
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
