List<String> tokenizeBracketedWord(String word) {
  final tokens = <String>[];
  final characters = word.toUpperCase().split('');
  for (var index = 0; index < characters.length; index++) {
    if (characters[index] != '[') {
      if (characters[index] == ']') {
        throw FormatException('Invalid bracketed letter in word: $word');
      }
      tokens.add(characters[index]);
      continue;
    }
    final closing = characters.indexOf(']', index + 1);
    if (closing < 0 ||
        closing == index + 1 ||
        characters.sublist(index + 1, closing).contains('[')) {
      throw FormatException('Invalid bracketed letter in word: $word');
    }
    tokens.add(characters.sublist(index + 1, closing).join());
    index = closing;
  }
  return List.unmodifiable(tokens);
}

String displayBracketedWord(String word) =>
    word.replaceAll('[', '').replaceAll(']', '');
