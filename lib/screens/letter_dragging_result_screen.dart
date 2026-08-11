import 'package:flutter/material.dart';

import '../widgets/feature_app_bar.dart';
import '../widgets/reward_gems.dart';

class LetterDraggingResultScreen extends StatelessWidget {
  final int score;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  const LetterDraggingResultScreen({
    required this.score,
    required this.onBack,
    required this.onRestart,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FeatureAppBar(title: 'Letter dragging', onBack: onBack),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Great work!\nYou collected $score gems.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 30),
              ),
              RewardGems(count: score),
              FilledButton(
                onPressed: onRestart,
                child: const Text('Play again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
