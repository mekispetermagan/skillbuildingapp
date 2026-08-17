enum NumberMemoryRange { oneToTwelve, oneToTwentyFour }

enum NumberMemoryCardKind { numeral, quantity }

enum NumberMemoryCardState { hidden, revealed, matched }

class NumberMemoryCardData {
  final int cardId;
  final int pairId;
  final NumberMemoryCardKind kind;
  final int number;
  final String emoji;
  final List<int> positions;
  final int gridSize;
  final NumberMemoryCardState state;
  final int revealOrder;

  const NumberMemoryCardData({
    required this.cardId,
    required this.pairId,
    required this.kind,
    required this.number,
    required this.emoji,
    required this.positions,
    required this.gridSize,
    this.state = NumberMemoryCardState.hidden,
    this.revealOrder = 0,
  });

  bool get isFaceUp => state != NumberMemoryCardState.hidden;
  bool get isMatched => state == NumberMemoryCardState.matched;

  NumberMemoryCardData copyWith({
    NumberMemoryCardState? state,
    int? revealOrder,
  }) => NumberMemoryCardData(
    cardId: cardId,
    pairId: pairId,
    kind: kind,
    number: number,
    emoji: emoji,
    positions: positions,
    gridSize: gridSize,
    state: state ?? this.state,
    revealOrder: revealOrder ?? this.revealOrder,
  );
}
