import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/l10n/l10n.dart';
import 'package:literacy_game/models/activity_id.dart';

void main() {
  test('English and Hungarian are supported interface locales', () {
    expect(AppLocalizations.supportedLocales, const [
      Locale('en'),
      Locale('hu'),
    ]);
  });

  test('every activity identity has an English interface label', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    expect(ActivityId.values.map((activity) => activity.label(l10n)), [
      'Letter learning',
      'Letter practice',
      'Phrase building',
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
    ]);
  });
}
