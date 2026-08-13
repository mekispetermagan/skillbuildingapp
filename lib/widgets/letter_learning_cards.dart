import 'package:flutter/material.dart';

import '../models/alphabet_letter.dart';
import '../models/letter_learning_slot.dart';
import 'alphabet_color.dart';

class LetterLearningSourceCard extends StatelessWidget {
  final AlphabetLetter data;
  final double size;
  final bool isEnabled;
  final ValueChanged<String> onGuess;

  const LetterLearningSourceCard({
    required this.data,
    required this.size,
    required this.isEnabled,
    required this.onGuess,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final background = alphabetColor(data.colorName);
    final card = SizedBox.square(
      dimension: size,
      child: Card(
        color: background,
        margin: const EdgeInsets.all(2),
        child: Center(
          child: Text(
            data.letter,
            style: TextStyle(
              color: readableTextColor(background),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
    if (!isEnabled) return Opacity(opacity: 0.5, child: card);
    return Draggable<String>(
      data: data.letter,
      feedback: Material(color: Colors.transparent, child: card),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: InkWell(onTap: () => onGuess(data.letter), child: card),
    );
  }
}

class LetterLearningWordCard extends StatelessWidget {
  final LetterLearningSlot slot;
  final double size;
  final bool revealTarget;
  final bool isEnabled;
  final ValueChanged<String> onGuess;

  const LetterLearningWordCard({
    required this.slot,
    required this.size,
    required this.revealTarget,
    required this.isEnabled,
    required this.onGuess,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = slot.colorName == null
        ? scheme.secondaryContainer
        : alphabetColor(slot.colorName!);
    final background = slot.isTarget
        ? Color.lerp(base, Colors.white, 0.18)!
        : slot.isInSelectedGroups
        ? Color.lerp(base, Colors.black, 0.18)!
        : scheme.secondaryContainer;
    final foreground = slot.isInSelectedGroups || slot.isTarget
        ? readableTextColor(background)
        : scheme.onSecondaryContainer;
    final dimension = slot.isTarget ? size + 8 : size;

    Widget card(bool hovering) => AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: dimension,
      height: dimension,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(
          color: hovering ? scheme.primary : scheme.outline,
          width: hovering ? 3 : 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          slot.isTarget && !revealTarget ? '' : slot.letter,
          style: TextStyle(
            color: foreground,
            fontSize: slot.isTarget ? 25 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    if (!slot.isTarget || !isEnabled) return card(false);
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onGuess(details.data),
      builder: (_, candidates, _) => card(candidates.isNotEmpty),
    );
  }
}
