import 'package:flutter/material.dart';

import 'rewards.dart';

class RewardRow extends StatelessWidget {
  final int count;

  const RewardRow({required this.count, super.key});

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 46, child: Rewards(count: count));
}
