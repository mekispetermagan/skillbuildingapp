import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/utils/string_utils.dart';

void main() {
  test('splits an English sentence into lowercase words', () {
    expect(toWords('The cat sits on the mat.'), [
      'the',
      'cat',
      'sits',
      'on',
      'the',
      'mat',
    ]);
  });
}
