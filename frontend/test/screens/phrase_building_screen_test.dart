import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/l10n/app_localizations.dart';
import 'package:literacy_game/models/phrase_building_state.dart';
import 'package:literacy_game/models/phrase_building_tile.dart';
import 'package:literacy_game/models/view_data.dart';
import 'package:literacy_game/screens/phrase_building_screen.dart';

void main() {
  testWidgets('supports dragging a word onto the whole target pool', (
    tester,
  ) async {
    const sourceTile = PhraseBuildingTile(id: 1, word: 'bird');
    PhraseBuildingTile? movedTile;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PhraseBuildingScreen(
          viewData: const PhraseBuildingViewData(
            isLoading: false,
            loadError: null,
            sourcePool: [sourceTile],
            targetPool: [],
            state: PhraseBuildingState.guessing,
            score: 0,
          ),
          onBack: () {},
          onMove: (_) {},
          canMoveToTarget: (tile) => tile == sourceTile,
          canMoveToSource: (_) => false,
          onMoveToTarget: (tile) => movedTile = tile,
          onMoveToSource: (_) {},
          onSubmit: null,
          onPlayAudio: () async {},
          onRestart: () {},
        ),
      ),
    );

    expect(find.byType(Draggable<PhraseBuildingTile>), findsOneWidget);
    final targetPool = find.byType(DragTarget<PhraseBuildingTile>).first;
    await tester.dragFrom(
      tester.getCenter(find.byKey(const ValueKey('source-1'))),
      tester.getCenter(targetPool) -
          tester.getCenter(find.byKey(const ValueKey('source-1'))),
    );
    await tester.pumpAndSettle();

    expect(movedTile, sourceTile);
  });
}
