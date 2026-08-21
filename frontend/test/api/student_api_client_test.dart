import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:skillbuilding_game/api/student_api_client.dart';
import 'package:skillbuilding_game/config/gameplay_api_config.dart';
import 'package:skillbuilding_game/models/authentication.dart';
import 'package:skillbuilding_game/models/student.dart';

void main() {
  final config = GameplayApiConfig(
    baseUri: Uri.parse('https://example.test/api/'),
    apiKey: 'test-key',
  );

  test('synchronizes students with account authorization', () async {
    late http.Request captured;
    final api = StudentApiClient(
      config: config,
      client: MockClient((request) async {
        captured = request;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(body['students']), 200);
      }),
    );
    final student = Student(
      id: 'student-1',
      name: 'Student One',
      location: 'Kampala',
      age: 10,
      gender: LearnerGender.female,
    );

    final result = await api.synchronize('account-token', [student]);

    expect(captured.url.path, '/api/students/sync');
    expect(captured.headers['Authorization'], 'Bearer account-token');
    expect(captured.headers['X-API-Key'], 'test-key');
    expect(jsonDecode(captured.body), {
      'students': [student.toJson()],
    });
    expect(result.single.id, student.id);
  });
}
