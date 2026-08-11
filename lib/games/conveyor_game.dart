import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import '../models/conveyor_world.dart';

class ConveyorGame extends FlameGame {
  final ConveyorWorld gameWorld;
  final void Function(double width, double height) onResize;
  final void Function(double deltaSeconds) onTick;
  final void Function() onFrame;

  ConveyorGame({
    required this.gameWorld,
    required this.onResize,
    required this.onTick,
    required this.onFrame,
  });

  @override
  Color backgroundColor() => const Color(0xff101318);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    onResize(size.x, size.y);
  }

  @override
  void update(double dt) {
    onTick(dt);
    onFrame();
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final beltPaint = Paint()..color = const Color(0xff252a31);
    final railPaint = Paint()
      ..color = const Color(0xff59616c)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final left = Rect.fromLTWH(
      gameWorld.leftBeltX,
      0,
      gameWorld.leftBeltWidth,
      gameWorld.height,
    );
    final right = Rect.fromLTWH(
      gameWorld.rightBeltX,
      0,
      gameWorld.config.rightBeltWidth,
      gameWorld.height,
    );
    canvas
      ..drawRect(left, beltPaint)
      ..drawRect(right, beltPaint)
      ..drawLine(left.topLeft, left.bottomLeft, railPaint)
      ..drawLine(left.topRight, left.bottomRight, railPaint)
      ..drawLine(right.topLeft, right.bottomLeft, railPaint)
      ..drawLine(right.topRight, right.bottomRight, railPaint);

    final stripePaint = Paint()
      ..color = const Color(0xff343b44)
      ..strokeWidth = 2;
    const stripeSpacing = 34.0;
    for (var y = 0.0; y < gameWorld.height; y += stripeSpacing) {
      canvas
        ..drawLine(Offset(left.left, y), Offset(left.right, y), stripePaint)
        ..drawLine(Offset(right.left, y), Offset(right.right, y), stripePaint);
    }
  }
}
