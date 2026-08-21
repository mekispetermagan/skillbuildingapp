import 'package:characters/characters.dart';

final _letterPattern = RegExp(r'^\p{L}$', unicode: true);

List<String> toWords(String text) {
  final result = <String>[];
  var currentWord = '';

  for (final character in text.toLowerCase().characters) {
    if (_letterPattern.hasMatch(character)) {
      currentWord += character;
    } else if (currentWord.isNotEmpty) {
      result.add(currentWord);
      currentWord = '';
    }
  }

  if (currentWord.isNotEmpty) result.add(currentWord);
  return result;
}
