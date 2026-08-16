import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/activity_id.dart';

class RatingScreen extends StatelessWidget {
  final ActivityId activity;
  final Future<void> Function(int rating) onRate;

  const RatingScreen({required this.activity, required this.onRate, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activity.label(l10n),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.rateActivity,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    for (var rating = 1; rating <= 5; rating++)
                      IconButton(
                        iconSize: 48,
                        color: Colors.amber.shade700,
                        tooltip: l10n.ratingStar(rating),
                        onPressed: () => onRate(rating),
                        icon: const Icon(Icons.star),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
