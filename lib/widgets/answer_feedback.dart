import 'package:flutter/material.dart';

import '../models/view_data.dart';

({Color background, Color? foreground}) answerFeedbackColors(
  BuildContext context,
  AnswerFeedback feedback, {
  bool transparentNeutral = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  return switch (feedback) {
    AnswerFeedback.correct => () {
      final successScheme = ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: scheme.brightness,
      );
      return (
        background: successScheme.primaryContainer,
        foreground: successScheme.onPrimaryContainer,
      );
    }(),
    AnswerFeedback.wrong => (
      background: scheme.errorContainer,
      foreground: scheme.onErrorContainer,
    ),
    AnswerFeedback.neutral => (
      background: transparentNeutral
          ? Colors.transparent
          : scheme.primaryContainer,
      foreground: transparentNeutral ? null : scheme.onPrimaryContainer,
    ),
  };
}
