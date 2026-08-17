import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/conveyor_config.dart';
import 'single_select_segments.dart';

class ConveyorDifficultySegments extends StatelessWidget {
  final ConveyorDifficulty value;
  final ValueChanged<ConveyorDifficulty> onChanged;

  const ConveyorDifficultySegments({
    required this.value,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) => SingleSelectSegments(
    choices: [
      SegmentChoice(
        value: ConveyorDifficulty.easy,
        label: context.l10n.difficultyEasy,
      ),
      SegmentChoice(
        value: ConveyorDifficulty.hard,
        label: context.l10n.difficultyHard,
      ),
    ],
    selected: value,
    onSelected: onChanged,
  );
}
