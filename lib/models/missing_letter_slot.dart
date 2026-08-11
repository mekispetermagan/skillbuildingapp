class MissingLetterSlot {
  final int id;
  final String letter;
  final bool isMissing;
  final int? placedTileId;

  const MissingLetterSlot({
    required this.id,
    required this.letter,
    required this.isMissing,
    this.placedTileId,
  });

  bool get isFilled => !isMissing || placedTileId != null;

  MissingLetterSlot fillWith(int tileId) => MissingLetterSlot(
    id: id,
    letter: letter,
    isMissing: isMissing,
    placedTileId: tileId,
  );
}
