import 'dart:math';

class MemoryCardPosition {
  final double x;
  final double y;
  final double size;

  const MemoryCardPosition({
    required this.x,
    required this.y,
    required this.size,
  });
}

class MemoryBoardLayout {
  final double cardSize;
  final double gap;
  final double xPadding;
  final double yPadding;
  final int columnCount;

  const MemoryBoardLayout({
    required this.cardSize,
    required this.gap,
    required this.xPadding,
    required this.yPadding,
    required this.columnCount,
  });

  factory MemoryBoardLayout.calculate({
    required double availableWidth,
    required double availableHeight,
    required double minimumPadding,
    required double gap,
    required int columnCount,
    required int rowCount,
  }) {
    final maximumWidth =
        (availableWidth - minimumPadding * 2 - gap * (columnCount - 1)) /
        columnCount;
    final maximumHeight =
        (availableHeight - minimumPadding * 2 - gap * (rowCount - 1)) /
        rowCount;
    final cardSize = max(0.0, min(maximumWidth, maximumHeight));
    final boardWidth = columnCount * cardSize + (columnCount - 1) * gap;
    final boardHeight = rowCount * cardSize + (rowCount - 1) * gap;
    return MemoryBoardLayout(
      cardSize: cardSize,
      gap: gap,
      xPadding: (availableWidth - boardWidth) / 2,
      yPadding: (availableHeight - boardHeight) / 2,
      columnCount: columnCount,
    );
  }

  MemoryCardPosition positionFor(int index) {
    final column = index % columnCount;
    final row = index ~/ columnCount;
    return MemoryCardPosition(
      x: xPadding + column * (cardSize + gap),
      y: yPadding + row * (cardSize + gap),
      size: cardSize,
    );
  }
}
