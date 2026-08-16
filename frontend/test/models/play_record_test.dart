import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/models/activity_id.dart';
import 'package:literacy_game/models/feature_metrics.dart';
import 'package:literacy_game/models/learning_area.dart';
import 'package:literacy_game/models/pending_completion.dart';
import 'package:literacy_game/models/play_outcome.dart';
import 'package:literacy_game/models/play_record.dart';

void main() {
  final startedAt = DateTime.utc(2026, 8, 16, 9);
  final completedAt = DateTime.utc(2026, 8, 16, 9, 2);

  PendingCompletion completion({FeatureMetrics? metrics, int? score = 10}) =>
      PendingCompletion(
        area: LearningArea.literacy,
        feature: ActivityId.phraseBuilding,
        outcome: PlayOutcome.won,
        score: score,
        metrics:
            metrics ?? AttemptMetrics(correctAnswers: 10, incorrectAttempts: 2),
        startedAt: startedAt,
        completedAt: completedAt,
        elapsedMilliseconds: 118000,
        appVersion: '0.1.0+1',
        contentVersion: 'en-1',
      );

  test('every current activity has a stable literacy identity', () {
    expect(
      ActivityId.values.map((feature) => feature.wireName).toSet(),
      hasLength(ActivityId.values.length),
    );
    expect(
      ActivityId.values.every(
        (feature) => feature.area == LearningArea.literacy,
      ),
      isTrue,
    );
    expect(
      ActivityId.fromWireName(
        area: LearningArea.literacy,
        value: 'letter_learning',
      ),
      ActivityId.letterLearning,
    );
  });

  test('a pending completion becomes a locally numbered rated record', () {
    final record = completion().rate(recordNumber: 17, rating: 4);

    expect(record.installationId, isNull);
    expect(record.recordNumber, 17);
    expect(record.rating, 4);
    expect(record.area, LearningArea.literacy);
    expect(record.feature, ActivityId.phraseBuilding);
  });

  test('play records round-trip through the wire representation', () {
    final original = completion().rate(
      installationId: 3,
      recordNumber: 17,
      rating: 4,
    );
    final decoded = PlayRecord.fromJson(original.toJson());

    expect(decoded.toJson(), original.toJson());
    expect(decoded.metrics, isA<AttemptMetrics>());
    expect((decoded.metrics as AttemptMetrics).incorrectAttempts, 2);
  });

  test('memory metrics allow a scoreless completed activity', () {
    final record = completion(
      score: null,
      metrics: MemoryMetrics(pairCount: 9, pairAttempts: 12, mismatches: 3),
    ).rate(recordNumber: 1, rating: 5);

    expect(record.score, isNull);
    expect(
      FeatureMetrics.fromJson(record.metrics.toJson()),
      isA<MemoryMetrics>(),
    );
  });

  test('record validation rejects invalid ratings and area mismatches', () {
    expect(
      () => completion().rate(recordNumber: 1, rating: 0),
      throwsArgumentError,
    );
    expect(
      () => PendingCompletion(
        area: LearningArea.math,
        feature: ActivityId.crossword,
        outcome: PlayOutcome.won,
        score: 3,
        metrics: AttemptMetrics(correctAnswers: 3, incorrectAttempts: 0),
        startedAt: startedAt,
        completedAt: completedAt,
        elapsedMilliseconds: 1000,
        appVersion: '1',
        contentVersion: '1',
      ),
      throwsArgumentError,
    );
  });

  test('metrics validate their feature-specific invariants', () {
    expect(
      () => LivesMetrics(
        correctAnswers: 3,
        incorrectAttempts: 6,
        startingLives: 5,
        remainingLives: 6,
      ),
      throwsArgumentError,
    );
    expect(
      () => MemoryMetrics(pairCount: 9, pairAttempts: 10, mismatches: 3),
      throwsArgumentError,
    );
  });
}
