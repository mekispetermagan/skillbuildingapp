import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/api/gameplay_api_client.dart';
import 'package:skillbuilding_game/models/activity_id.dart';
import 'package:skillbuilding_game/models/feature_metrics.dart';
import 'package:skillbuilding_game/models/learning_area.dart';
import 'package:skillbuilding_game/models/pending_completion.dart';
import 'package:skillbuilding_game/models/play_outcome.dart';
import 'package:skillbuilding_game/models/play_record.dart';
import 'package:skillbuilding_game/models/record_sync.dart';
import 'package:skillbuilding_game/services/gameplay_recorder.dart';
import 'package:skillbuilding_game/storage/gameplay_record_store.dart';

void main() {
  PendingCompletion completion({PlayOutcome outcome = PlayOutcome.won}) =>
      PendingCompletion(
        area: LearningArea.literacy,
        feature: ActivityId.phraseBuilding,
        outcome: outcome,
        score: outcome == PlayOutcome.abandoned ? 3 : 10,
        metrics: AttemptMetrics(correctAnswers: 3, incorrectAttempts: 2),
        startedAt: DateTime.utc(2026, 8, 16, 9),
        completedAt: DateTime.utc(2026, 8, 16, 9, 2),
        elapsedMilliseconds: 120000,
        appVersion: '0.1.0+1',
        contentVersion: 'en-1',
      );

  test('network failure leaves a newly completed record queued', () async {
    final store = MemoryGameplayRecordStore();
    final api = FakeGameplayApi()..resolveError = Exception('offline');
    final recorder = SyncedGameplayRecorder(store, api);

    await recorder.recordCompleted(completion(), 4);

    expect(store.state.records, hasLength(1));
    expect(store.state.records.single.rating, 4);
    expect(store.state.installationId, isNull);
  });

  test(
    'successful synchronization assigns identity and clears the queue',
    () async {
      final store = MemoryGameplayRecordStore();
      final api = FakeGameplayApi();
      final recorder = SyncedGameplayRecorder(store, api);

      await recorder.recordAbandoned(
        completion(outcome: PlayOutcome.abandoned),
      );
      await recorder.synchronize();

      expect(api.submitted.single.installationId, 3);
      expect(api.submitted.single.records.single.recordNumber, 1);
      expect(api.submitted.single.records.single.rating, isNull);
      expect(store.state.installationId, 3);
      expect(store.state.nextRecordNumber, 2);
      expect(store.state.records, isEmpty);
    },
  );

  test(
    'assigns the selected student and token to synchronized records',
    () async {
      final store = MemoryGameplayRecordStore();
      final api = FakeGameplayApi();
      final recorder = SyncedGameplayRecorder(store, api)
        ..setPlayer(
          const GameplayPlayer.student('student-abc', 'teacher-token'),
        );

      await recorder.recordCompleted(completion(), 5);
      await recorder.synchronize();

      final submitted = api.submitted.single.records.single;
      expect(submitted.playerType, GameplayPlayerType.student);
      expect(submitted.studentClientId, 'student-abc');
      expect(api.accessTokens, ['teacher-token']);
    },
  );

  test('captures the player before a queued record operation runs', () async {
    final store = MemoryGameplayRecordStore();
    final api = FakeGameplayApi()..resolveError = Exception('offline');
    final recorder = SyncedGameplayRecorder(store, api)
      ..setPlayer(const GameplayPlayer.student('first-student', 'token'));

    final saving = recorder.recordAbandoned(
      completion(outcome: PlayOutcome.abandoned),
    );
    recorder.setPlayer(const GameplayPlayer.student('next-student', 'token'));
    await saving;

    expect(store.state.records.single.studentClientId, 'first-student');
  });

  test('backend sequence confirms a record whose response was lost', () async {
    final pending = completion().rate(
      installationId: 3,
      recordNumber: 1,
      rating: 5,
    );
    final store = MemoryGameplayRecordStore(
      GameplayRecordStoreState(
        installationId: 3,
        nextRecordNumber: 1,
        records: [pending],
      ),
    );
    final api = FakeGameplayApi(nextRecordNumber: 2);
    final recorder = SyncedGameplayRecorder(store, api);

    await recorder.synchronize();

    expect(api.submitted, isEmpty);
    expect(store.state.records, isEmpty);
    expect(store.state.nextRecordNumber, 2);
  });

  test(
    'unknown installation is replaced and queued records are renumbered',
    () async {
      final pending = completion().rate(
        installationId: 99,
        recordNumber: 8,
        rating: 3,
      );
      final store = MemoryGameplayRecordStore(
        GameplayRecordStoreState(
          installationId: 99,
          nextRecordNumber: 9,
          records: [pending],
        ),
      );
      final api = FakeGameplayApi()..unknownInstallationId = 99;
      final recorder = SyncedGameplayRecorder(store, api);

      await recorder.synchronize();

      expect(api.resolveIds, [99, null]);
      expect(api.submitted.single.records.single.installationId, 3);
      expect(api.submitted.single.records.single.recordNumber, 1);
      expect(store.state.records, isEmpty);
    },
  );
}

class MemoryGameplayRecordStore implements GameplayRecordStore {
  GameplayRecordStoreState state;

  MemoryGameplayRecordStore([GameplayRecordStoreState? state])
    : state = state ?? GameplayRecordStoreState.empty();

  @override
  Future<GameplayRecordStoreState> load() async => state;

  @override
  Future<void> save(GameplayRecordStoreState state) async {
    this.state = state;
  }
}

class FakeGameplayApi implements GameplayApi {
  int nextRecordNumber;
  Object? resolveError;
  int? unknownInstallationId;
  final List<int?> resolveIds = [];
  final List<RecordBatch> submitted = [];
  final List<String?> accessTokens = [];

  FakeGameplayApi({this.nextRecordNumber = 1});

  @override
  Future<InstallationRegistration> resolveInstallation(
    int? installationId,
  ) async {
    resolveIds.add(installationId);
    final error = resolveError;
    if (error != null) throw error;
    if (unknownInstallationId != null &&
        installationId == unknownInstallationId) {
      throw const UnknownInstallationException('unknown');
    }
    return InstallationRegistration(
      installationId: installationId ?? 3,
      nextRecordNumber: nextRecordNumber,
    );
  }

  @override
  Future<RecordBatchAcknowledgement> submit(
    RecordBatch batch, {
    String? accessToken,
  }) async {
    submitted.add(batch);
    accessTokens.add(accessToken);
    nextRecordNumber =
        batch.records
            .map((record) => record.recordNumber)
            .reduce((first, second) => first > second ? first : second) +
        1;
    return RecordBatchAcknowledgement(
      installationId: batch.installationId,
      nextRecordNumber: nextRecordNumber,
      acknowledgements: [
        for (final record in batch.records)
          RecordAcknowledgement(
            recordNumber: record.recordNumber,
            status: RecordAcknowledgementStatus.accepted,
          ),
      ],
    );
  }
}
