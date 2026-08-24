import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/student_group.dart';

abstract interface class StudentGroupStore {
  Future<List<StudentGroup>> load(int teacherAccountId);
  Future<void> save(int teacherAccountId, List<StudentGroup> groups);
}

class SharedPreferencesStudentGroupStore implements StudentGroupStore {
  final SharedPreferencesAsync _preferences;

  SharedPreferencesStudentGroupStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  String _key(int teacherAccountId) =>
      'teacher_student_groups_v1_$teacherAccountId';

  @override
  Future<List<StudentGroup>> load(int teacherAccountId) async {
    final encoded = await _preferences.getString(_key(teacherAccountId));
    if (encoded == null) return const [];
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return [
        for (final item in decoded)
          StudentGroup.fromStoredJson(item as Map<String, dynamic>),
      ];
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> save(int teacherAccountId, List<StudentGroup> groups) =>
      _preferences.setString(
        _key(teacherAccountId),
        jsonEncode([for (final group in groups) group.toStoredJson()]),
      );
}
