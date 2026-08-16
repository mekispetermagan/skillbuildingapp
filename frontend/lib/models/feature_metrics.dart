sealed class FeatureMetrics {
  const FeatureMetrics();

  String get type;
  int get schemaVersion => 1;

  Map<String, Object> toJson();

  static FeatureMetrics fromJson(Map<String, dynamic> json) {
    final type = _requiredString(json, 'type');
    final schemaVersion = _requiredInt(json, 'schema_version');
    if (schemaVersion != 1) {
      throw FormatException('Unsupported metrics schema: $schemaVersion');
    }
    return switch (type) {
      AttemptMetrics.typeName => AttemptMetrics(
        correctAnswers: _requiredInt(json, 'correct_answers'),
        incorrectAttempts: _requiredInt(json, 'incorrect_attempts'),
      ),
      TimedWordMetrics.typeName => TimedWordMetrics(
        correctAnswers: _requiredInt(json, 'correct_answers'),
        passedItems: _requiredInt(json, 'passed_items'),
      ),
      LivesMetrics.typeName => LivesMetrics(
        correctAnswers: _requiredInt(json, 'correct_answers'),
        incorrectAttempts: _requiredInt(json, 'incorrect_attempts'),
        startingLives: _requiredInt(json, 'starting_lives'),
        remainingLives: _requiredInt(json, 'remaining_lives'),
      ),
      MemoryMetrics.typeName => MemoryMetrics(
        pairCount: _requiredInt(json, 'pair_count'),
        pairAttempts: _requiredInt(json, 'pair_attempts'),
        mismatches: _requiredInt(json, 'mismatches'),
      ),
      _ => throw FormatException('Unknown metrics type: $type'),
    };
  }
}

class AttemptMetrics extends FeatureMetrics {
  static const typeName = 'attempts';

  final int correctAnswers;
  final int incorrectAttempts;

  AttemptMetrics({
    required this.correctAnswers,
    required this.incorrectAttempts,
  }) {
    _requireNonNegative(correctAnswers, 'correctAnswers');
    _requireNonNegative(incorrectAttempts, 'incorrectAttempts');
  }

  int get totalAttempts => correctAnswers + incorrectAttempts;

  @override
  String get type => typeName;

  @override
  Map<String, Object> toJson() => {
    'type': type,
    'schema_version': schemaVersion,
    'correct_answers': correctAnswers,
    'incorrect_attempts': incorrectAttempts,
  };
}

class TimedWordMetrics extends FeatureMetrics {
  static const typeName = 'timed_words';

  final int correctAnswers;
  final int passedItems;

  TimedWordMetrics({required this.correctAnswers, required this.passedItems}) {
    _requireNonNegative(correctAnswers, 'correctAnswers');
    _requireNonNegative(passedItems, 'passedItems');
  }

  @override
  String get type => typeName;

  @override
  Map<String, Object> toJson() => {
    'type': type,
    'schema_version': schemaVersion,
    'correct_answers': correctAnswers,
    'passed_items': passedItems,
  };
}

class LivesMetrics extends FeatureMetrics {
  static const typeName = 'lives';

  final int correctAnswers;
  final int incorrectAttempts;
  final int startingLives;
  final int remainingLives;

  LivesMetrics({
    required this.correctAnswers,
    required this.incorrectAttempts,
    required this.startingLives,
    required this.remainingLives,
  }) {
    _requireNonNegative(correctAnswers, 'correctAnswers');
    _requireNonNegative(incorrectAttempts, 'incorrectAttempts');
    if (startingLives <= 0) {
      throw ArgumentError.value(
        startingLives,
        'startingLives',
        'Must be positive',
      );
    }
    if (remainingLives < 0 || remainingLives > startingLives) {
      throw ArgumentError.value(
        remainingLives,
        'remainingLives',
        'Must be between zero and startingLives',
      );
    }
  }

  @override
  String get type => typeName;

  @override
  Map<String, Object> toJson() => {
    'type': type,
    'schema_version': schemaVersion,
    'correct_answers': correctAnswers,
    'incorrect_attempts': incorrectAttempts,
    'starting_lives': startingLives,
    'remaining_lives': remainingLives,
  };
}

class MemoryMetrics extends FeatureMetrics {
  static const typeName = 'memory';

  final int pairCount;
  final int pairAttempts;
  final int mismatches;

  MemoryMetrics({
    required this.pairCount,
    required this.pairAttempts,
    required this.mismatches,
  }) {
    if (pairCount <= 0) {
      throw ArgumentError.value(pairCount, 'pairCount', 'Must be positive');
    }
    _requireNonNegative(mismatches, 'mismatches');
    if (pairAttempts != pairCount + mismatches) {
      throw ArgumentError.value(
        pairAttempts,
        'pairAttempts',
        'Must equal pairCount plus mismatches',
      );
    }
  }

  @override
  String get type => typeName;

  @override
  Map<String, Object> toJson() => {
    'type': type,
    'schema_version': schemaVersion,
    'pair_count': pairCount,
    'pair_attempts': pairAttempts,
    'mismatches': mismatches,
  };
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

void _requireNonNegative(int value, String name) {
  if (value < 0) throw ArgumentError.value(value, name, 'Must not be negative');
}
