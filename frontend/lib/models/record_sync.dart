import 'play_record.dart';

enum RecordAcknowledgementStatus {
  accepted('accepted'),
  alreadyAccepted('already_accepted'),
  storedAsConflict('stored_as_conflict');

  final String wireName;

  const RecordAcknowledgementStatus(this.wireName);

  static RecordAcknowledgementStatus fromWireName(String value) =>
      values.firstWhere(
        (status) => status.wireName == value,
        orElse: () => throw FormatException('Unknown acknowledgement: $value'),
      );
}

class InstallationRegistration {
  final int installationId;
  final int nextRecordNumber;

  InstallationRegistration({
    required this.installationId,
    required this.nextRecordNumber,
  }) {
    _requirePositive(installationId, 'installationId');
    _requirePositive(nextRecordNumber, 'nextRecordNumber');
  }

  factory InstallationRegistration.fromJson(Map<String, dynamic> json) =>
      InstallationRegistration(
        installationId: recordInt(json, 'installation_id'),
        nextRecordNumber: recordInt(json, 'next_record_number'),
      );
}

class RecordAcknowledgement {
  final int recordNumber;
  final RecordAcknowledgementStatus status;
  final String? conflictReference;

  RecordAcknowledgement({
    required this.recordNumber,
    required this.status,
    this.conflictReference,
  }) {
    _requirePositive(recordNumber, 'recordNumber');
    if (status == RecordAcknowledgementStatus.storedAsConflict &&
        (conflictReference == null || conflictReference!.trim().isEmpty)) {
      throw ArgumentError('A stored conflict needs a conflict reference.');
    }
    if (status != RecordAcknowledgementStatus.storedAsConflict &&
        conflictReference != null) {
      throw ArgumentError(
        'Only stored conflicts may have a conflict reference.',
      );
    }
  }

  factory RecordAcknowledgement.fromJson(Map<String, dynamic> json) =>
      RecordAcknowledgement(
        recordNumber: recordInt(json, 'record_number'),
        status: RecordAcknowledgementStatus.fromWireName(
          recordString(json, 'status'),
        ),
        conflictReference: json['conflict_reference'] as String?,
      );
}

class RecordBatch {
  final int installationId;
  final List<PlayRecord> records;

  RecordBatch({required this.installationId, required List<PlayRecord> records})
    : records = List.unmodifiable(records) {
    _requirePositive(installationId, 'installationId');
    if (records.isEmpty) {
      throw ArgumentError('A submission batch must not be empty.');
    }
    final numbers = <int>{};
    for (final record in records) {
      if (record.installationId != installationId) {
        throw ArgumentError(
          'Every record must have the batch installation ID.',
        );
      }
      if (!numbers.add(record.recordNumber)) {
        throw ArgumentError(
          'A batch must not contain duplicate record numbers.',
        );
      }
    }
  }

  Map<String, Object> toJson() => {
    'installation_id': installationId,
    'records': [for (final record in records) record.toJson()],
  };
}

class RecordBatchAcknowledgement {
  final int installationId;
  final int nextRecordNumber;
  final List<RecordAcknowledgement> acknowledgements;

  RecordBatchAcknowledgement({
    required this.installationId,
    required this.nextRecordNumber,
    required List<RecordAcknowledgement> acknowledgements,
  }) : acknowledgements = List.unmodifiable(acknowledgements) {
    _requirePositive(installationId, 'installationId');
    _requirePositive(nextRecordNumber, 'nextRecordNumber');
    final numbers = <int>{};
    if (acknowledgements.any((item) => !numbers.add(item.recordNumber))) {
      throw ArgumentError('Acknowledgements must have unique record numbers.');
    }
  }

  factory RecordBatchAcknowledgement.fromJson(Map<String, dynamic> json) {
    final rawAcknowledgements = json['acknowledgements'];
    if (rawAcknowledgements is! List<dynamic>) {
      throw const FormatException('acknowledgements must be a list.');
    }
    return RecordBatchAcknowledgement(
      installationId: recordInt(json, 'installation_id'),
      nextRecordNumber: recordInt(json, 'next_record_number'),
      acknowledgements: [
        for (final item in rawAcknowledgements)
          RecordAcknowledgement.fromJson(item as Map<String, dynamic>),
      ],
    );
  }
}

void _requirePositive(int value, String name) {
  if (value <= 0) throw ArgumentError.value(value, name, 'Must be positive');
}
