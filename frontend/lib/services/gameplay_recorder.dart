import '../api/gameplay_api_client.dart';
import '../models/pending_completion.dart';
import '../models/play_record.dart';
import '../models/record_sync.dart';
import '../storage/gameplay_record_store.dart';

abstract interface class GameplayRecorder {
  Future<void> synchronize();
  Future<void> recordCompleted(PendingCompletion completion, int rating);
  Future<void> recordAbandoned(PendingCompletion completion);
}

abstract interface class PlayerAwareGameplayRecorder {
  void setPlayer(GameplayPlayer? player);
}

class NoopGameplayRecorder implements GameplayRecorder {
  const NoopGameplayRecorder();

  @override
  Future<void> synchronize() async {}

  @override
  Future<void> recordCompleted(
    PendingCompletion completion,
    int rating,
  ) async {}

  @override
  Future<void> recordAbandoned(PendingCompletion completion) async {}
}

class SyncedGameplayRecorder
    implements GameplayRecorder, PlayerAwareGameplayRecorder {
  static const _maximumBatchSize = 100;

  final GameplayRecordStore _store;
  final GameplayApi _api;
  Future<void> _operations = Future.value();
  GameplayPlayer? _player;

  SyncedGameplayRecorder(this._store, this._api);

  @override
  void setPlayer(GameplayPlayer? player) => _player = player;

  @override
  Future<void> synchronize() => _enqueue(_synchronize);

  @override
  Future<void> recordCompleted(PendingCompletion completion, int rating) {
    final player = _player;
    final saved = _enqueue(() async {
      final state = await _store.load();
      final record = completion
          .rate(
            recordNumber: _nextLocalNumber(state),
            rating: rating,
            installationId: state.installationId,
          )
          .withPlayer(player);
      await _append(state, record);
    });
    _synchronizeAfter(saved);
    return saved;
  }

  @override
  Future<void> recordAbandoned(PendingCompletion completion) {
    final player = _player;
    final saved = _enqueue(() async {
      final state = await _store.load();
      final record = completion
          .abandon(
            recordNumber: _nextLocalNumber(state),
            installationId: state.installationId,
          )
          .withPlayer(player);
      await _append(state, record);
    });
    _synchronizeAfter(saved);
    return saved;
  }

  void _synchronizeAfter(Future<void> saved) {
    saved.then((_) => synchronize()).ignore();
  }

  Future<void> _append(GameplayRecordStoreState state, PlayRecord record) =>
      _store.save(
        GameplayRecordStoreState(
          installationId: state.installationId,
          nextRecordNumber: state.nextRecordNumber,
          records: [...state.records, record],
        ),
      );

  int _nextLocalNumber(GameplayRecordStoreState state) {
    var next = state.nextRecordNumber;
    for (final record in state.records) {
      if (record.recordNumber >= next) next = record.recordNumber + 1;
    }
    return next;
  }

  Future<void> _synchronize() async {
    var state = await _store.load();
    InstallationRegistration registration;
    try {
      registration = await _api.resolveInstallation(state.installationId);
    } on UnknownInstallationException {
      try {
        registration = await _api.resolveInstallation(null);
      } catch (_) {
        return;
      }
    } catch (_) {
      return;
    }

    state = _reconcile(state, registration);
    await _store.save(state);

    while (state.records.isNotEmpty) {
      final firstToken = state.records.first.accessToken;
      final records = state.records
          .takeWhile((record) => record.accessToken == firstToken)
          .take(_maximumBatchSize)
          .toList();
      RecordBatchAcknowledgement acknowledgement;
      try {
        acknowledgement = await _api.submit(
          RecordBatch(
            installationId: registration.installationId,
            records: records,
          ),
          accessToken: firstToken,
        );
      } on UnknownInstallationException {
        await _store.save(
          GameplayRecordStoreState(
            installationId: null,
            nextRecordNumber: 1,
            records: state.records,
          ),
        );
        return;
      } catch (_) {
        return;
      }

      final acknowledgedNumbers = {
        for (final item in acknowledgement.acknowledgements) item.recordNumber,
      };
      state = GameplayRecordStoreState(
        installationId: acknowledgement.installationId,
        nextRecordNumber: acknowledgement.nextRecordNumber,
        records: [
          for (final record in state.records)
            if (!acknowledgedNumbers.contains(record.recordNumber)) record,
        ],
      );
      await _store.save(state);
    }
  }

  GameplayRecordStoreState _reconcile(
    GameplayRecordStoreState state,
    InstallationRegistration registration,
  ) {
    final sameInstallation =
        state.installationId == registration.installationId;
    final pending = sameInstallation
        ? state.records
              .where(
                (record) =>
                    record.recordNumber >= registration.nextRecordNumber,
              )
              .toList()
        : state.records.toList();
    pending.sort(
      (first, second) => first.recordNumber.compareTo(second.recordNumber),
    );

    return GameplayRecordStoreState(
      installationId: registration.installationId,
      nextRecordNumber: registration.nextRecordNumber,
      records: [
        for (final (index, record) in pending.indexed)
          record.withIdentity(
            installationId: registration.installationId,
            recordNumber: registration.nextRecordNumber + index,
          ),
      ],
    );
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _operations.then((_) => operation());
    _operations = result.catchError((_) {});
    return result;
  }
}
