import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/models/sentence_quiz_sentence.dart';

void main() {
  test('uses natural shirt grammar and derives its asset path', () {
    const sentence = SentenceQuizSentence(
      person: SentencePerson.sarah,
      color: GarmentColor.green,
      piece: ClothingPiece.shirt,
    );

    expect(sentence.text, 'Sarah is wearing a green shirt.');
    expect(
      sentence.imagePath,
      'assets/images/sentence_building/sarah_shirt_green.svg',
    );
  });

  test('uses plural jeans grammar and derives its asset path', () {
    const sentence = SentenceQuizSentence(
      person: SentencePerson.timothy,
      color: GarmentColor.blue,
      piece: ClothingPiece.jeans,
    );

    expect(sentence.text, 'Timothy is wearing blue jeans.');
    expect(
      sentence.imagePath,
      'assets/images/sentence_building/timothy_jeans_blue.svg',
    );
  });
}
