enum MemoryCardKind { word, image }

enum MemoryCardState { hidden, revealed, matched }

class MemoryCardData {
  final int cardId;
  final int pairId;
  final MemoryCardKind kind;
  final String content;
  final MemoryCardState state;
  final int revealOrder;

  const MemoryCardData({
    required this.cardId,
    required this.pairId,
    required this.kind,
    required this.content,
    this.state = MemoryCardState.hidden,
    this.revealOrder = 0,
  });

  bool get isFaceUp => state != MemoryCardState.hidden;
  bool get isMatched => state == MemoryCardState.matched;

  MemoryCardData copyWith({MemoryCardState? state, int? revealOrder}) =>
      MemoryCardData(
        cardId: cardId,
        pairId: pairId,
        kind: kind,
        content: content,
        state: state ?? this.state,
        revealOrder: revealOrder ?? this.revealOrder,
      );
}
