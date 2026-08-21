import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/gameplay_api_config.dart';
import '../models/student.dart';
import 'gameplay_api_client.dart';

abstract interface class StudentApi {
  Future<List<Student>> list(String accessToken);
  Future<List<Student>> synchronize(String accessToken, List<Student> students);
}

class StudentApiClient implements StudentApi {
  final GameplayApiConfig config;
  final http.Client _client;
  final Duration requestTimeout;

  StudentApiClient({
    required this.config,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 5),
  }) : _client = client ?? http.Client();

  @override
  Future<List<Student>> list(String accessToken) async {
    final response = await _client
        .get(config.endpoint('/students'), headers: _headers(accessToken))
        .timeout(requestTimeout);
    return _parse(response);
  }

  @override
  Future<List<Student>> synchronize(
    String accessToken,
    List<Student> students,
  ) async {
    final response = await _client
        .put(
          config.endpoint('/students/sync'),
          headers: _headers(accessToken),
          body: jsonEncode({
            'students': [for (final student in students) student.toJson()],
          }),
        )
        .timeout(requestTimeout);
    return _parse(response);
  }

  Map<String, String> _headers(String token) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-API-Key': config.apiKey,
    'Authorization': 'Bearer $token',
  };

  List<Student> _parse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GameplayApiException(response.statusCode, response.body);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) {
      throw const FormatException('The student response must be a list.');
    }
    return [
      for (final item in decoded)
        Student.fromJson(item as Map<String, dynamic>),
    ];
  }

  void close() => _client.close();
}
