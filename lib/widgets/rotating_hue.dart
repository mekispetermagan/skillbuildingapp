import 'dart:math';

import 'package:flutter/material.dart';

ColorFilter _hueRotation(double degrees) {
  final radians = degrees * pi / 180;
  final cosA = cos(radians);
  final sinA = sin(radians);
  return ColorFilter.matrix([
    0.213 + cosA * 0.787 - sinA * 0.213,
    0.715 - cosA * 0.715 - sinA * 0.715,
    0.072 - cosA * 0.072 + sinA * 0.928,
    0,
    0,
    0.213 - cosA * 0.213 + sinA * 0.143,
    0.715 + cosA * 0.285 + sinA * 0.140,
    0.072 - cosA * 0.072 - sinA * 0.283,
    0,
    0,
    0.213 - cosA * 0.213 - sinA * 0.787,
    0.715 - cosA * 0.715 + sinA * 0.715,
    0.072 + cosA * 0.928 + sinA * 0.072,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);
}

class RotatingHue extends StatefulWidget {
  final Widget child;
  final double degreesPerSecond;

  const RotatingHue({
    required this.child,
    this.degreesPerSecond = 24,
    super.key,
  });

  static double? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RotatingHueScope>()?.angle;

  @override
  State<RotatingHue> createState() => _RotatingHueState();
}

class _RotatingHueState extends State<RotatingHue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (360000 / widget.degreesPerSecond).round(),
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) =>
          _RotatingHueScope(angle: _controller.value * 360, child: child!),
      child: widget.child,
    );
  }
}

class RotatingHueImage extends StatelessWidget {
  final Image image;
  final double angleOffset;

  const RotatingHueImage({
    required this.image,
    this.angleOffset = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final angle = (RotatingHue.of(context) ?? 0) + angleOffset;
    return ColorFiltered(colorFilter: _hueRotation(angle), child: image);
  }
}

class _RotatingHueScope extends InheritedWidget {
  final double angle;

  const _RotatingHueScope({required this.angle, required super.child});

  @override
  bool updateShouldNotify(_RotatingHueScope oldWidget) =>
      angle != oldWidget.angle;
}
