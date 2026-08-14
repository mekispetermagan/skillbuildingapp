import 'package:flutter/widgets.dart';

enum InterfaceLanguage {
  english(Locale('en'), 'English'),
  german(Locale('de'), 'Deutsch'),
  hungarian(Locale('hu'), 'Magyar');

  final Locale locale;
  final String nativeName;

  const InterfaceLanguage(this.locale, this.nativeName);
}
