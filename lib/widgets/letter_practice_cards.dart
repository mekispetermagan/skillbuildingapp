import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import '../models/alphabet_letter.dart';
import '../models/letter_practice_slot.dart';
import 'alphabet_color.dart';

class LetterPracticeSourceCard extends StatelessWidget {
  final AlphabetLetter data;
  final double size;
  final bool isSelected;
  final bool isEnabled;
  final ValueChanged<String> onSelect;

  const LetterPracticeSourceCard({
    required this.data,
    required this.size,
    required this.isSelected,
    required this.isEnabled,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = alphabetColor(data.colorName);
    final background = isSelected
        ? Color.lerp(baseColor, Colors.black, 0.25)!
        : baseColor;
    final card = SizedBox.square(
      dimension: size,
      child: Card(
        color: background,
        margin: const EdgeInsets.all(2),
        shape: RoundedRectangleBorder(
          side: isSelected
              ? BorderSide(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 3,
                )
              : BorderSide.none,
          borderRadius: BorderRadius.circular(10),
        ),
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
      onDragStarted: isSelected ? null : () => onSelect(data.letter),
      feedback: Material(color: Colors.transparent, child: card),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: InkWell(onTap: () => onSelect(data.letter), child: card),
    );
  }
}

class LetterPracticeTargetCard extends StatelessWidget {
  final LetterPracticeSlot slot;
  final double size;
  final bool useColors;
  final bool isEnabled;
  final String? selectedLetter;
  final bool Function({required int slotId, required String letter}) canPlace;
  final Future<void> Function(int slotId) onPlaceSelected;
  final Future<void> Function({required int slotId, required String letter})
  onPlace;

  const LetterPracticeTargetCard({
    required this.slot,
    required this.size,
    required this.useColors,
    required this.isEnabled,
    required this.selectedLetter,
    required this.canPlace,
    required this.onPlaceSelected,
    required this.onPlace,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (slot.isSpace) return SizedBox(width: size * 0.55, height: size);
    final scheme = Theme.of(context).colorScheme;
    final shouldColor = useColors && slot.isTarget && slot.colorName != null;
    final background = shouldColor
        ? alphabetColor(slot.colorName!)
        : scheme.secondaryContainer;
    final foreground = shouldColor
        ? readableTextColor(background)
        : scheme.onSecondaryContainer;

    Widget card(bool isCandidate, bool isCorrectCandidate) => Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(
          color: isCandidate
              ? isCorrectCandidate
                    ? scheme.primary
                    : scheme.error
              : scheme.outline,
          width: isCandidate ? 3 : 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          slot.isRevealed ? slot.letter : '',
          style: TextStyle(
            color: foreground,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    if (!slot.isTarget || slot.isFilled || !isEnabled) {
      return card(false, false);
    }
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) =>
          onPlace(slotId: slot.id, letter: details.data),
      builder: (_, candidates, _) {
        final candidate = candidates.firstOrNull;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: selectedLetter == null ? null : () => onPlaceSelected(slot.id),
          child: card(
            candidate != null,
            candidate != null && canPlace(slotId: slot.id, letter: candidate),
          ),
        );
      },
    );
  }
}
