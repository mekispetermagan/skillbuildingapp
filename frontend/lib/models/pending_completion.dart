import 'activity_id.dart';
import 'feature_metrics.dart';
import 'learning_area.dart';
import 'play_outcome.dart';
import 'play_record.dart';

class PendingCompletion {
  final LearningArea area;
  final ActivityId feature;
  final PlayOutcome outcome;
  final int? score;
  final FeatureMetrics metrics;
  final DateTime startedAt;
  final DateTime completedAt;
  final int elapsedMilliseconds;
  final String appVersion;
  final String contentVersion;

  PendingCompletion({
    required this.area,
    required this.feature,
    required this.outcome,
    required this.score,
    required this.metrics,
    required this.startedAt,
    required this.completedAt,
    required this.elapsedMilliseconds,
    required this.appVersion,
    required this.contentVersion,
  }) {
    _validateCompletion(
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

  PlayRecord rate({
    required int recordNumber,
    required int rating,
    int? installationId,
  }) => PlayRecord(
    installationId: installationId,
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
  );

  Map<String, Object?> toJson() => {
    'area_id': area.wireName,
    'feature_id': feature.wireName,
    'outcome': outcome.wireName,
    'score': score,
    'metrics': metrics.toJson(),
    'started_at': startedAt.toUtc().toIso8601String(),
    'completed_at': completedAt.toUtc().toIso8601String(),
    'elapsed_milliseconds': elapsedMilliseconds,
    'app_version': appVersion,
    'content_version': contentVersion,
  };

  factory PendingCompletion.fromJson(Map<String, dynamic> json) {
    final area = LearningArea.fromWireName(_string(json, 'area_id'));
    return PendingCompletion(
      area: area,
      feature: ActivityId.fromWireName(
        area: area,
        value: _string(json, 'feature_id'),
      ),
      outcome: PlayOutcome.fromWireName(_string(json, 'outcome')),
      score: _nullableInt(json, 'score'),
      metrics: FeatureMetrics.fromJson(_map(json, 'metrics')),
      startedAt: _dateTime(json, 'started_at'),
      completedAt: _dateTime(json, 'completed_at'),
      elapsedMilliseconds: _int(json, 'elapsed_milliseconds'),
      appVersion: _string(json, 'app_version'),
      contentVersion: _string(json, 'content_version'),
    );
  }
}

void _validateCompletion({
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

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

int _int(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

int? _nullableInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value != null && value is! int) {
    throw FormatException('$key must be an integer or null.');
  }
  return value as int?;
}

DateTime _dateTime(Map<String, dynamic> json, String key) {
  final value = _string(json, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('$key must be an ISO-8601 timestamp.');
  }
  return parsed.toUtc();
}

Map<String, dynamic> _map(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map<String, dynamic>) {
    throw FormatException('$key must be an object.');
  }
  return value;
}
