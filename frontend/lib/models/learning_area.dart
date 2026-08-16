enum LearningArea {
  literacy('literacy'),
  math('math');

  final String wireName;

  const LearningArea(this.wireName);

  static LearningArea fromWireName(String value) => values.firstWhere(
    (area) => area.wireName == value,
    orElse: () => throw FormatException('Unknown learning area: $value'),
  );
}
