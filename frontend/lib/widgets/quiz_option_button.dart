import 'package:flutter/material.dart';

import '../models/answer_feedback.dart';
import 'answer_feedback.dart';

class QuizOptionButton extends StatelessWidget {
  final String label;
  final AnswerFeedback feedback;
  final VoidCallback? onPressed;

  const QuizOptionButton({
    required this.label,
    required this.feedback,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = answerFeedbackColors(context, feedback);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FilledButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(colors.background),
          foregroundColor: WidgetStatePropertyAll(colors.foreground),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
