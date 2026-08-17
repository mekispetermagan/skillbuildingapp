import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/l10n/l10n.dart';
import 'package:literacy_game/models/activity_id.dart';

void main() {
  test('English, German, and Hungarian are supported interface locales', () {
    expect(
      AppLocalizations.supportedLocales,
      unorderedEquals(const [Locale('en'), Locale('de'), Locale('hu')]),
    );
  });

  test('every activity identity has a German interface label', () {
    final l10n = lookupAppLocalizations(const Locale('de'));

    expect(ActivityId.values.map((activity) => activity.label(l10n)), [
      'Buchstaben lernen',
      'Buchstaben üben',
      'Sätze bauen',
      'Buchstaben ordnen',
      'Fehlende Buchstaben',
      'Buchstaben schießen',
      'Memorykarten',
      'Buchstaben fangen',
      'Wortförderband',
      'Satzquiz',
      'Satz zusammenstellen',
      'Rechtschreibquiz',
      'Kreuzworträtsel',
      'Zahlen lernen',
      'Zahlen vergleichen',
      'Rechenzeichen-Förderband',
    ]);
  });

  test('every activity identity has an English interface label', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    expect(ActivityId.values.map((activity) => activity.label(l10n)), [
      'Letter learning',
      'Letter practice',
      'Sentence building',
      'Letter dragging',
      'Missing letters',
      'Letter shooting',
      'Memory cards',
      'Letter catching',
      'Word conveyor',
      'Sentence quiz',
      'Sentence composer',
      'Spelling quiz',
      'Crossword',
      'Number learning',
      'Compare numbers',
      'Operator conveyor',
    ]);
  });

  test('every activity identity has a Hungarian interface label', () {
    final l10n = lookupAppLocalizations(const Locale('hu'));

    expect(ActivityId.values.map((activity) => activity.label(l10n)), [
      'Betűtanuló',
      'Betűgyakorló',
      'Mondatkirakó',
      'Betűrendező',
      'Betűpótló',
      'Betűágyú',
      'Memóriakártyák',
      'Betűfogás',
      'Futószalagos',
      'Mondatos kvíz',
      'Mondatépítő',
      'Helyesírás kvíz',
      'Keresztrejtvény',
      'Számtanulás',
      'Számok összehasonlítása',
      'Műveleti futószalag',
    ]);
  });
}
