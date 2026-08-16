enum PlayOutcome {
  completed('completed'),
  won('won'),
  lost('lost');

  final String wireName;

  const PlayOutcome(this.wireName);

  static PlayOutcome fromWireName(String value) => values.firstWhere(
    (outcome) => outcome.wireName == value,
    orElse: () => throw FormatException('Unknown play outcome: $value'),
  );
}
