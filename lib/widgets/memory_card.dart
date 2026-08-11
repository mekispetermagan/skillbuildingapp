import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/memory_card_data.dart';

class MemoryCard extends StatelessWidget {
  static const _flipDuration = Duration(milliseconds: 450);
  static const _hideDuration = Duration(milliseconds: 350);

  final MemoryCardData data;
  final Offset expandedOffset;
  final VoidCallback onPressed;

  const MemoryCard({
    required this.data,
    required this.expandedOffset,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: data.isFaceUp,
      child: AnimatedOpacity(
        opacity: data.isMatched ? 0 : 1,
        duration: _hideDuration,
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: data.isFaceUp ? expandedOffset : Offset.zero,
          duration: _flipDuration,
          curve: Curves.easeInOutCubic,
          child: AnimatedScale(
            scale: data.isFaceUp ? 2 : 1,
            duration: _flipDuration,
            curve: Curves.easeInOutCubic,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: data.isFaceUp ? 1 : 0),
              duration: _flipDuration,
              curve: Curves.easeInOutCubic,
              builder: (context, turn, _) {
                final showFace = turn >= 0.5;
                final rotation = Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(math.pi * turn);
                return Transform(
                  alignment: Alignment.center,
                  transform: rotation,
                  child: showFace
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(math.pi),
                          child: _CardFace(data: data),
                        )
                      : _CardBack(kind: data.kind, onPressed: onPressed),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final MemoryCardKind kind;
  final VoidCallback onPressed;

  const _CardBack({required this.kind, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isWord = kind == MemoryCardKind.word;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: isWord ? colors.primaryContainer : colors.tertiaryContainer,
      child: InkWell(
        onTap: onPressed,
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              color: isWord
                  ? colors.onPrimaryContainer
                  : colors.onTertiaryContainer,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final MemoryCardData data;

  const _CardFace({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isWord = data.kind == MemoryCardKind.word;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: isWord ? colors.primary : colors.tertiary,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Center(
          child: isWord
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    data.content,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : Image.asset(
                  data.content,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.image_outlined,
                    color: colors.onTertiary,
                    size: 30,
                  ),
                ),
        ),
      ),
    );
  }
}
