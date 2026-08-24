import 'dart:math';

class StudentGroup {
  final String id;
  final String name;
  final List<String> studentIds;
  final int? ownerAccountId;
  final bool isOwner;
  final bool pendingChanges;

  StudentGroup({
    required this.id,
    required String name,
    required Iterable<String> studentIds,
    this.ownerAccountId,
    required this.isOwner,
    this.pendingChanges = false,
  }) : name = name.trim(),
       studentIds = List.unmodifiable(studentIds) {
    if (id.trim().isEmpty || id.length > 64) {
      throw ArgumentError.value(id, 'id', 'Must be 1–64 characters');
    }
    if (this.name.isEmpty || this.name.length > 100) {
      throw ArgumentError.value(name, 'name', 'Must be 1–100 characters');
    }
    if (this.studentIds.toSet().length != this.studentIds.length) {
      throw ArgumentError.value(studentIds, 'studentIds', 'Must be unique');
    }
  }

  factory StudentGroup.create({
    required String name,
    required int ownerAccountId,
    Iterable<String> studentIds = const [],
  }) => StudentGroup(
    id: _newGroupId(),
    name: name,
    studentIds: studentIds,
    ownerAccountId: ownerAccountId,
    isOwner: true,
    pendingChanges: true,
  );

  StudentGroup copyWith({
    String? name,
    Iterable<String>? studentIds,
    bool pendingChanges = true,
  }) => StudentGroup(
    id: id,
    name: name ?? this.name,
    studentIds: studentIds ?? this.studentIds,
    ownerAccountId: ownerAccountId,
    isOwner: isOwner,
    pendingChanges: pendingChanges,
  );

  Map<String, Object> toJson() => {
    'client_id': id,
    'name': name,
    'student_client_ids': studentIds,
  };

  Map<String, Object?> toStoredJson() => {
    ...toJson(),
    'owner_account_id': ownerAccountId,
    'is_owner': isOwner,
    'pending_changes': pendingChanges,
  };

  factory StudentGroup.fromJson(Map<String, dynamic> json) => StudentGroup(
    id: json['client_id'] as String,
    name: json['name'] as String,
    studentIds: (json['student_client_ids'] as List<dynamic>).cast<String>(),
    ownerAccountId: json['owner_account_id'] as int?,
    isOwner: json['is_owner'] as bool? ?? true,
    pendingChanges: false,
  );

  factory StudentGroup.fromStoredJson(Map<String, dynamic> json) =>
      StudentGroup(
        id: json['client_id'] as String,
        name: json['name'] as String,
        studentIds: (json['student_client_ids'] as List<dynamic>)
            .cast<String>(),
        ownerAccountId: json['owner_account_id'] as int?,
        isOwner: json['is_owner'] as bool? ?? true,
        pendingChanges: json['pending_changes'] as bool? ?? false,
      );
}

String _newGroupId() {
  final random = Random.secure();
  final milliseconds = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final suffix = List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return '$milliseconds-$suffix';
}
