import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import '../controllers/conveyor_controller.dart';

class ConveyorGame extends FlameGame {
  final ConveyorController controller;

  ConveyorGame(this.controller);

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
    final beltPaint = Paint()..color = const Color(0xff252a31);
    final railPaint = Paint()
      ..color = const Color(0xff59616c)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final left = Rect.fromLTWH(
      world.leftBeltX,
      0,
      world.leftBeltWidth,
      world.height,
    );
    final right = Rect.fromLTWH(
      world.rightBeltX,
      0,
      world.config.rightBeltWidth,
      world.height,
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
    for (var y = 0.0; y < world.height; y += stripeSpacing) {
      canvas
        ..drawLine(Offset(left.left, y), Offset(left.right, y), stripePaint)
        ..drawLine(Offset(right.left, y), Offset(right.right, y), stripePaint);
    }
  }
}
