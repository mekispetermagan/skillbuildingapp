import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

class ImageVisibilitySegments extends StatelessWidget {
  final bool showImages;
  final ValueChanged<bool> onChanged;

  const ImageVisibilitySegments({
    required this.showImages,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) => SegmentedButton<bool>(
    segments: [
      ButtonSegment(value: true, label: Text(context.l10n.imagesOn)),
      ButtonSegment(value: false, label: Text(context.l10n.imagesOff)),
    ],
    selected: {showImages},
    onSelectionChanged: (selection) => onChanged(selection.single),
  );
}
