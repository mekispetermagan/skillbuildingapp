import 'package:flutter/material.dart';

import '../models/answer_feedback.dart';
import 'answer_feedback.dart';

class SegmentChoice<T> {
  final T value;
  final String label;
  final AnswerFeedback feedback;

  const SegmentChoice({
    required this.value,
    required this.label,
    this.feedback = AnswerFeedback.neutral,
  });
}

class SingleSelectSegments<T> extends StatelessWidget {
  final List<SegmentChoice<T>> choices;
  final T? selected;
  final ValueChanged<T>? onSelected;

  const SingleSelectSegments({
    required this.choices,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) => SegmentedButton<T>(
    segments: [
      for (final choice in choices)
        ButtonSegment<T>(
          value: choice.value,
          label: _SegmentLabel(label: choice.label, feedback: choice.feedback),
        ),
    ],
    selected: selected == null ? <T>{} : <T>{selected as T},
    emptySelectionAllowed: true,
    showSelectedIcon: false,
    expandedInsets: EdgeInsets.zero,
    onSelectionChanged: onSelected == null
        ? null
        : (values) {
            if (values.isNotEmpty) onSelected!(values.single);
          },
  );
}

class _SegmentLabel extends StatelessWidget {
  final String label;
  final AnswerFeedback feedback;

  const _SegmentLabel({required this.label, required this.feedback});

  @override
  Widget build(BuildContext context) {
    final colors = answerFeedbackColors(
      context,
      feedback,
      transparentNeutral: true,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Text(label, style: TextStyle(color: colors.foreground)),
      ),
    );
  }
}
