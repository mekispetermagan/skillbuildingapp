import 'package:flutter/material.dart';

import '../models/missing_letter_slot.dart';
import '../models/missing_letter_tile.dart';
import '../models/missing_letters_state.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/letter_dragging_rewards.dart';
import '../widgets/missing_letter_card.dart';

class MissingLettersScreen extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<MissingLetterSlot> slots;
  final List<MissingLetterTile> pool;
  final MissingLettersState state;
  final int score;
  final VoidCallback onBack;
  final VoidCallback? onNext;
  final bool Function({required int targetId, required int tileId}) canDrop;
  final void Function({required int targetId, required int tileId}) onDrop;

  const MissingLettersScreen({
    required this.isLoading,
    required this.errorMessage,
    required this.slots,
    required this.pool,
    required this.state,
    required this.score,
    required this.onBack,
    required this.onNext,
    required this.canDrop,
    required this.onDrop,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FeatureAppBar(title: 'Missing letters', onBack: onBack),
      body: switch ((isLoading, errorMessage)) {
        (true, _) => const Center(child: CircularProgressIndicator()),
        (_, final String message) => Center(child: Text(message)),
        _ => _buildExercise(context),
      },
    );
  }

  Widget _buildExercise(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Drag the missing letters into the word',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (final slot in slots)
                  slot.isMissing
                      ? MissingLetterTargetCard(
                          key: ValueKey('target-${slot.id}'),
                          slot: slot,
                          canDrop: canDrop,
                          onDrop: onDrop,
                        )
                      : MissingLetterCard(
                          key: ValueKey('letter-${slot.id}'),
                          letter: slot.letter,
                          backgroundColor: scheme.primaryContainer,
                          foregroundColor: scheme.onPrimaryContainer,
                        ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tile in pool)
                  DraggableMissingLetterCard(
                    key: ValueKey('pool-${tile.id}'),
                    tile: tile,
                  ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 34),
              child: LetterDraggingRewards(count: score),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onNext,
                child: Text(
                  state == MissingLettersState.solved ? 'Next' : 'Find both',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
