import 'dart:math';

import 'authentication.dart';

class Student {
  final String id;
  final String name;
  final String location;
  final int age;
  final LearnerGender gender;

  Student({
    required this.id,
    required String name,
    required String location,
    required this.age,
    required this.gender,
  }) : name = name.trim(),
       location = location.trim() {
    if (id.trim().isEmpty || id.length > 64) {
      throw ArgumentError.value(id, 'id', 'Must be 1–64 characters');
    }
    if (this.name.isEmpty || this.name.length > 100) {
      throw ArgumentError.value(name, 'name', 'Must be 1–100 characters');
    }
    if (this.location.isEmpty || this.location.length > 100) {
      throw ArgumentError.value(
        location,
        'location',
        'Must be 1–100 characters',
      );
    }
    if (age < 1 || age > 120) {
      throw ArgumentError.value(age, 'age', 'Must be between 1 and 120');
    }
  }

  factory Student.create({
    required String name,
    required String location,
    required int age,
    required LearnerGender gender,
  }) => Student(
    id: _newStudentId(),
    name: name,
    location: location,
    age: age,
    gender: gender,
  );

  Map<String, Object> toJson() => {
    'client_id': id,
    'name': name,
    'location': location,
    'age': age,
    'gender': gender.wireName,
  };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: _storedId(json),
    name: json['name'] as String,
    location: json['location'] as String,
    age: json['age'] as int,
    gender: LearnerGender.fromWireName(json['gender'] as String),
  );
}

String _storedId(Map<String, dynamic> json) {
  final current = json['client_id'];
  if (current is String && current.isNotEmpty) return current;
  final legacy = json['id'];
  if (legacy is int) return 'legacy-$legacy';
  throw const FormatException('student client_id is missing.');
}

String _newStudentId() {
  final random = Random.secure();
  final milliseconds = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final suffix = List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return '$milliseconds-$suffix';
}
