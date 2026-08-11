import 'package:flutter/material.dart';

import 'rotating_hue.dart';

class Rewards extends StatelessWidget {
  final int count;

  const Rewards({required this.count, super.key});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return RotatingHue(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: [
          for (var index = 0; index < count; index++)
            RotatingHueImage(
              angleOffset: index * 60,
              image: Image.asset(
                'assets/images/reward.png',
                width: 36,
                height: 34,
              ),
            ),
        ],
      ),
    );
  }
}
