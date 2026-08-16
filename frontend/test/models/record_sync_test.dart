import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/models/activity_id.dart';
import 'package:literacy_game/models/feature_metrics.dart';
import 'package:literacy_game/models/learning_area.dart';
import 'package:literacy_game/models/play_outcome.dart';
import 'package:literacy_game/models/play_record.dart';
import 'package:literacy_game/models/record_sync.dart';

PlayRecord record(int number, {int installationId = 3}) => PlayRecord(
  installationId: installationId,
  recordNumber: number,
  area: LearningArea.literacy,
  feature: ActivityId.spellingQuiz,
  outcome: PlayOutcome.won,
  score: 10,
  rating: 4,
  metrics: AttemptMetrics(correctAnswers: 10, incorrectAttempts: 2),
  startedAt: DateTime.utc(2026, 8, 16, 9),
  completedAt: DateTime.utc(2026, 8, 16, 9, 2),
  elapsedMilliseconds: 120000,
  appVersion: '0.1.0+1',
  contentVersion: 'en-1',
);

void main() {
  test('registration accepts a backend sequence identity', () {
    final registration = InstallationRegistration.fromJson(const {
      'installation_id': 3,
      'next_record_number': 18,
    });

    expect(registration.installationId, 3);
    expect(registration.nextRecordNumber, 18);
  });

  test('a submission batch requires matching installed records', () {
    final batch = RecordBatch(
      installationId: 3,
      records: [record(17), record(18)],
    );

    expect(batch.toJson()['records'], hasLength(2));
    expect(
      () => RecordBatch(
        installationId: 3,
        records: [record(17, installationId: 4)],
      ),
      throwsArgumentError,
    );
    expect(
      () => RecordBatch(installationId: 3, records: [record(17), record(17)]),
      throwsArgumentError,
    );
  });

  test('parses accepted, repeated, and quarantined acknowledgements', () {
    final response = RecordBatchAcknowledgement.fromJson(const {
      'installation_id': 3,
      'next_record_number': 21,
      'acknowledgements': [
        {'record_number': 17, 'status': 'accepted'},
        {'record_number': 18, 'status': 'already_accepted'},
        {
          'record_number': 19,
          'status': 'stored_as_conflict',
          'conflict_reference': '3-19-e1',
        },
      ],
    });

    expect(response.acknowledgements, hasLength(3));
    expect(
      response.acknowledgements.last.status,
      RecordAcknowledgementStatus.storedAsConflict,
    );
    expect(response.acknowledgements.last.conflictReference, '3-19-e1');
  });

  test('a quarantined acknowledgement requires its backend reference', () {
    expect(
      () => RecordAcknowledgement(
        recordNumber: 19,
        status: RecordAcknowledgementStatus.storedAsConflict,
      ),
      throwsArgumentError,
    );
  });
}
