import 'package:flutter/widgets.dart';

enum InterfaceLanguage {
  english(Locale('en'), 'English'),
  german(Locale('de'), 'Deutsch'),
  hungarian(Locale('hu'), 'Magyar');

  final Locale locale;
  final String nativeName;

  const InterfaceLanguage(this.locale, this.nativeName);

  String get wireName => locale.languageCode;

  static InterfaceLanguage fromWireName(String value) => values.firstWhere(
    (language) => language.wireName == value,
    orElse: () => throw FormatException('Unknown interface language: $value'),
  );
}
