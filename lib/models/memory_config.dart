class MemoryConfig {
  final int pairCount;
  final int columnCount;

  const MemoryConfig({required this.pairCount, required this.columnCount})
    : assert(pairCount > 0),
      assert(columnCount > 0),
      assert(pairCount * 2 % columnCount == 0);

  int get cardCount => pairCount * 2;
  int get rowCount => cardCount ~/ columnCount;
}
