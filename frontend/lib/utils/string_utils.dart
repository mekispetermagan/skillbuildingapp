import 'package:characters/characters.dart';

final List<String> _alphabet = 'abcdefghijklmnopqrstuvwxyz'.characters.toList();

List<String> toWords(String text) {
  final result = <String>[];
  var currentWord = '';

  for (final character in text.toLowerCase().characters) {
    if (_alphabet.contains(character)) {
      currentWord += character;
    } else if (currentWord.isNotEmpty) {
      result.add(currentWord);
      currentWord = '';
    }
  }

  if (currentWord.isNotEmpty) result.add(currentWord);
  return result;
}
