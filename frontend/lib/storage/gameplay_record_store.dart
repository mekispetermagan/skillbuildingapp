import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/play_record.dart';

class GameplayRecordStoreState {
  final int? installationId;
  final int nextRecordNumber;
  final List<PlayRecord> records;

  GameplayRecordStoreState({
    required this.installationId,
    required this.nextRecordNumber,
    required List<PlayRecord> records,
  }) : records = List.unmodifiable(records);

  factory GameplayRecordStoreState.empty() => GameplayRecordStoreState(
    installationId: null,
    nextRecordNumber: 1,
    records: const [],
  );

  Map<String, Object?> toJson() => {
    'installation_id': installationId,
    'next_record_number': nextRecordNumber,
    'records': [for (final record in records) record.toJson()],
  };

  factory GameplayRecordStoreState.fromJson(Map<String, dynamic> json) {
    final rawRecords = json['records'];
    if (rawRecords is! List<dynamic>) {
      throw const FormatException('records must be a list.');
    }
    final installationId = json['installation_id'];
    final nextRecordNumber = json['next_record_number'];
    if (installationId != null && installationId is! int) {
      throw const FormatException(
        'installation_id must be an integer or null.',
      );
    }
    if (nextRecordNumber is! int || nextRecordNumber <= 0) {
      throw const FormatException('next_record_number must be positive.');
    }
    return GameplayRecordStoreState(
      installationId: installationId as int?,
      nextRecordNumber: nextRecordNumber,
      records: [
        for (final item in rawRecords)
          PlayRecord.fromJson(item as Map<String, dynamic>),
      ],
    );
  }
}

abstract interface class GameplayRecordStore {
  Future<GameplayRecordStoreState> load();
  Future<void> save(GameplayRecordStoreState state);
}

class SharedPreferencesGameplayRecordStore implements GameplayRecordStore {
  static const _storageKey = 'gameplay_record_queue_v1';

  final SharedPreferencesAsync _preferences;

  SharedPreferencesGameplayRecordStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  @override
  Future<GameplayRecordStoreState> load() async {
    final encoded = await _preferences.getString(_storageKey);
    if (encoded == null) return GameplayRecordStoreState.empty();
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      return GameplayRecordStoreState.fromJson(decoded);
    } on FormatException {
      return GameplayRecordStoreState.empty();
    }
  }

  @override
  Future<void> save(GameplayRecordStoreState state) =>
      _preferences.setString(_storageKey, jsonEncode(state.toJson()));
}
