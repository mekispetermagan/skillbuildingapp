import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/l10n/app_localizations.dart';
import 'package:literacy_game/models/missing_letter_slot.dart';
import 'package:literacy_game/models/missing_letter_tile.dart';
import 'package:literacy_game/models/missing_letters_state.dart';
import 'package:literacy_game/models/view_data.dart';
import 'package:literacy_game/screens/missing_letters_screen.dart';

void main() {
  testWidgets('shows two targets and seven draggable pool cards', (
    tester,
  ) async {
    const slots = [
      MissingLetterSlot(id: 0, letter: 'G', isMissing: false),
      MissingLetterSlot(id: 1, letter: 'O', isMissing: true),
      MissingLetterSlot(id: 2, letter: 'R', isMissing: false),
      MissingLetterSlot(id: 3, letter: 'L', isMissing: true),
    ];
    const pool = [
      MissingLetterTile(id: 0, letter: 'A'),
      MissingLetterTile(id: 1, letter: 'L'),
      MissingLetterTile(id: 2, letter: 'G'),
      MissingLetterTile(id: 3, letter: 'O'),
      MissingLetterTile(id: 4, letter: 'W'),
      MissingLetterTile(id: 5, letter: 'B'),
      MissingLetterTile(id: 6, letter: 'E'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MissingLettersScreen(
          viewData: MissingLettersViewData(
            isLoading: false,
            loadError: null,
            slots: slots,
            pool: pool,
            state: MissingLettersState.solving,
            score: 0,
            selectedTileId: null,
            imagePath: 'assets/images/ugandan_animals/gorilla.png',
            showImages: true,
          ),
          onBack: () {},
          onNext: null,
          canDrop: ({required targetId, required tileId}) => false,
          onDrop: ({required targetId, required tileId}) {},
          onSelectTile: (_) {},
          onPlaceSelected: (_) {},
          onShowImagesChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Drag the missing letters into the word'), findsOneWidget);
    expect(find.text('?'), findsNWidgets(2));
    expect(find.byType(Draggable<MissingLetterTile>), findsNWidgets(7));
    expect(find.text('Find both'), findsOneWidget);
  });
}
