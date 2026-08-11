import 'package:flutter/material.dart';

import '../models/phrase_building_tile.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/feature_load_state.dart';
import '../widgets/phrase_building_card.dart';

class PhraseBuildingScreen extends StatelessWidget {
  final PhraseBuildingViewData viewData;
  final VoidCallback onBack;
  final void Function(PhraseBuildingTile)? onMove;
  final Future<void> Function()? onSubmit;
  final Future<void> Function() onPlayAudio;

  const PhraseBuildingScreen({
    required this.viewData,
    required this.onBack,
    required this.onMove,
    required this.onSubmit,
    required this.onPlayAudio,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FeatureAppBar(title: 'Phrase building', onBack: onBack),
      body: FeatureLoadState(
        isLoading: viewData.isLoading,
        errorMessage: viewData.errorMessage,
        child: _buildExercise(),
      ),
    );
  }

  Widget _buildExercise() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final tile in viewData.targetPool)
                      PhraseBuildingCard(
                        key: ValueKey('target-${tile.id}'),
                        tile: tile,
                        state: viewData.state,
                        onMove: onMove,
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 32),
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final tile in viewData.sourcePool)
                      PhraseBuildingCard(
                        key: ValueKey('source-${tile.id}'),
                        tile: tile,
                        state: viewData.state,
                        onMove: onMove,
                      ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: onPlayAudio,
                  icon: const Icon(Icons.volume_up),
                  iconSize: 36,
                  tooltip: 'Play sentence',
                ),
                FilledButton(onPressed: onSubmit, child: const Text('Check')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
