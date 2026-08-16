import 'package:flutter/material.dart';

import 'rotating_hue.dart';

class RewardGems extends StatelessWidget {
  final int count;

  const RewardGems({required this.count, super.key});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: RotatingHue(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < count; index++) ...[
              if (index > 0) const SizedBox(width: 2),
              RotatingHueImage(
                angleOffset: index * 60,
                image: Image.asset(
                  'assets/images/reward_gem.png',
                  width: 36,
                  height: 34,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
