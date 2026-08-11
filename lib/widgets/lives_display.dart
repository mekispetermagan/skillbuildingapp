import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LivesDisplay extends StatelessWidget {
  final int lives;
  final int maximumLives;
  final double size;
  final double spacing;

  const LivesDisplay({
    required this.lives,
    required this.maximumLives,
    this.size = 24,
    this.spacing = 2,
    super.key,
  }) : assert(maximumLives >= 0),
       assert(lives >= 0 && lives <= maximumLives);

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$lives of $maximumLives lives remaining',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < maximumLives; index++) ...[
          if (index > 0) SizedBox(width: spacing),
          SvgPicture.asset(
            index < lives
                ? 'assets/images/lives/heart_good.svg'
                : 'assets/images/lives/heart_bad.svg',
            key: ValueKey(
              index < lives ? 'life-good-$index' : 'life-bad-$index',
            ),
            width: size,
            height: size,
          ),
        ],
      ],
    ),
  );
}
