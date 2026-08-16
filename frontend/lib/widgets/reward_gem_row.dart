import 'package:flutter/material.dart';

import 'reward_gems.dart';

class RewardGemRow extends StatelessWidget {
  final int count;

  const RewardGemRow({required this.count, super.key});

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 46, child: RewardGems(count: count));
}
