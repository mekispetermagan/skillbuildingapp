import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/student.dart';

abstract interface class StudentStore {
  Future<List<Student>> load(int teacherAccountId);
  Future<void> save(int teacherAccountId, List<Student> students);
}

class SharedPreferencesStudentStore implements StudentStore {
  final SharedPreferencesAsync _preferences;

  SharedPreferencesStudentStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  String _key(int teacherAccountId) => 'teacher_students_v1_$teacherAccountId';

  @override
  Future<List<Student>> load(int teacherAccountId) async {
    final encoded = await _preferences.getString(_key(teacherAccountId));
    if (encoded == null) return const [];
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return [
        for (final item in decoded)
          Student.fromJson(item as Map<String, dynamic>),
      ];
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> save(int teacherAccountId, List<Student> students) =>
      _preferences.setString(
        _key(teacherAccountId),
        jsonEncode([for (final student in students) student.toJson()]),
      );
}
