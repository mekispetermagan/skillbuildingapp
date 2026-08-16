import 'activity_id.dart';
import 'feature_metrics.dart';
import 'learning_area.dart';
import 'play_outcome.dart';

const playRecordSchemaVersion = 1;

class PlayRecord {
  final int? installationId;
  final int recordNumber;
  final LearningArea area;
  final ActivityId feature;
  final PlayOutcome outcome;
  final int? score;
  final int rating;
  final FeatureMetrics metrics;
  final DateTime startedAt;
  final DateTime completedAt;
  final int elapsedMilliseconds;
  final String appVersion;
  final String contentVersion;
  final int schemaVersion;

  PlayRecord({
    required this.installationId,
    required this.recordNumber,
    required this.area,
    required this.feature,
    required this.outcome,
    required this.score,
    required this.rating,
    required this.metrics,
    required this.startedAt,
    required this.completedAt,
    required this.elapsedMilliseconds,
    required this.appVersion,
    required this.contentVersion,
    this.schemaVersion = playRecordSchemaVersion,
  }) {
    if (installationId != null && installationId! <= 0) {
      throw ArgumentError.value(
        installationId,
        'installationId',
        'Must be positive',
      );
    }
    if (recordNumber <= 0) {
      throw ArgumentError.value(
        recordNumber,
        'recordNumber',
        'Must be positive',
      );
    }
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Must be between 1 and 5');
    }
    if (schemaVersion != playRecordSchemaVersion) {
      throw ArgumentError.value(
        schemaVersion,
        'schemaVersion',
        'Unsupported version',
      );
    }
    validatePlayCompletion(
      area: area,
      feature: feature,
      score: score,
      startedAt: startedAt,
      completedAt: completedAt,
      elapsedMilliseconds: elapsedMilliseconds,
      appVersion: appVersion,
      contentVersion: contentVersion,
    );
  }

  PlayRecord withInstallationId(int value) => PlayRecord(
    installationId: value,
    recordNumber: recordNumber,
    area: area,
    feature: feature,
    outcome: outcome,
    score: score,
    rating: rating,
    metrics: metrics,
    startedAt: startedAt,
    completedAt: completedAt,
    elapsedMilliseconds: elapsedMilliseconds,
    appVersion: appVersion,
    contentVersion: contentVersion,
    schemaVersion: schemaVersion,
  );

  Map<String, Object?> toJson() => {
    'schema_version': schemaVersion,
    'installation_id': installationId,
    'record_number': recordNumber,
    'area_id': area.wireName,
    'feature_id': feature.wireName,
    'outcome': outcome.wireName,
    'score': score,
    'rating': rating,
    'metrics': metrics.toJson(),
    'started_at': startedAt.toUtc().toIso8601String(),
    'completed_at': completedAt.toUtc().toIso8601String(),
    'elapsed_milliseconds': elapsedMilliseconds,
    'app_version': appVersion,
    'content_version': contentVersion,
  };

  factory PlayRecord.fromJson(Map<String, dynamic> json) {
    final area = LearningArea.fromWireName(recordString(json, 'area_id'));
    return PlayRecord(
      installationId: recordNullableInt(json, 'installation_id'),
      recordNumber: recordInt(json, 'record_number'),
      area: area,
      feature: ActivityId.fromWireName(
        area: area,
        value: recordString(json, 'feature_id'),
      ),
      outcome: PlayOutcome.fromWireName(recordString(json, 'outcome')),
      score: recordNullableInt(json, 'score'),
      rating: recordInt(json, 'rating'),
      metrics: FeatureMetrics.fromJson(recordMap(json, 'metrics')),
      startedAt: recordDateTime(json, 'started_at'),
      completedAt: recordDateTime(json, 'completed_at'),
      elapsedMilliseconds: recordInt(json, 'elapsed_milliseconds'),
      appVersion: recordString(json, 'app_version'),
      contentVersion: recordString(json, 'content_version'),
      schemaVersion: recordInt(json, 'schema_version'),
    );
  }
}

void validatePlayCompletion({
  required LearningArea area,
  required ActivityId feature,
  required int? score,
  required DateTime startedAt,
  required DateTime completedAt,
  required int elapsedMilliseconds,
  required String appVersion,
  required String contentVersion,
}) {
  if (feature.area != area) {
    throw ArgumentError(
      'Feature ${feature.wireName} does not belong to ${area.wireName}.',
    );
  }
  if (score != null && score < 0) {
    throw ArgumentError.value(score, 'score', 'Must not be negative');
  }
  if (completedAt.isBefore(startedAt)) {
    throw ArgumentError('completedAt must not be before startedAt.');
  }
  if (elapsedMilliseconds < 0) {
    throw ArgumentError.value(
      elapsedMilliseconds,
      'elapsedMilliseconds',
      'Must not be negative',
    );
  }
  if (appVersion.trim().isEmpty || contentVersion.trim().isEmpty) {
    throw ArgumentError('Version values must not be empty.');
  }
}

String recordString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

int recordInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

int? recordNullableInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value != null && value is! int) {
    throw FormatException('$key must be an integer or null.');
  }
  return value as int?;
}

DateTime recordDateTime(Map<String, dynamic> json, String key) {
  final parsed = DateTime.tryParse(recordString(json, key));
  if (parsed == null) {
    throw FormatException('$key must be an ISO-8601 timestamp.');
  }
  return parsed.toUtc();
}

Map<String, dynamic> recordMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map<String, dynamic>) {
    throw FormatException('$key must be an object.');
  }
  return value;
}
