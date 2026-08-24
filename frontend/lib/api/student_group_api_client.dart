import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/gameplay_api_config.dart';
import '../models/student_group.dart';
import 'gameplay_api_client.dart';

abstract interface class StudentGroupApi {
  Future<List<StudentGroup>> list(String accessToken);
  Future<List<StudentGroup>> synchronize(
    String accessToken,
    List<StudentGroup> groups,
  );
  Future<String> generateShareCode(String accessToken, String groupId);
  Future<StudentGroup> join(String accessToken, String code);
}

class StudentGroupApiClient implements StudentGroupApi {
  final GameplayApiConfig config;
  final http.Client _client;
  final Duration requestTimeout;

  StudentGroupApiClient({
    required this.config,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 5),
  }) : _client = client ?? http.Client();

  @override
  Future<List<StudentGroup>> list(String accessToken) async {
    final response = await _client
        .get(config.endpoint('/groups'), headers: _headers(accessToken))
        .timeout(requestTimeout);
    return _parseList(response);
  }

  @override
  Future<List<StudentGroup>> synchronize(
    String accessToken,
    List<StudentGroup> groups,
  ) async {
    final response = await _client
        .put(
          config.endpoint('/groups/sync'),
          headers: _headers(accessToken),
          body: jsonEncode({
            'groups': [for (final group in groups) group.toJson()],
          }),
        )
        .timeout(requestTimeout);
    return _parseList(response);
  }

  @override
  Future<String> generateShareCode(String accessToken, String groupId) async {
    final response = await _client
        .post(
          config.endpoint('/groups/$groupId/share-code'),
          headers: _headers(accessToken),
        )
        .timeout(requestTimeout);
    final decoded = _parseObject(response);
    return decoded['code'] as String;
  }

  @override
  Future<StudentGroup> join(String accessToken, String code) async {
    final response = await _client
        .post(
          config.endpoint('/groups/join'),
          headers: _headers(accessToken),
          body: jsonEncode({'code': code}),
        )
        .timeout(requestTimeout);
    return StudentGroup.fromJson(_parseObject(response));
  }

  Map<String, String> _headers(String token) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-API-Key': config.apiKey,
    'Authorization': 'Bearer $token',
  };

  List<StudentGroup> _parseList(http.Response response) {
    _requireSuccess(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) {
      throw const FormatException('The group response must be a list.');
    }
    return [
      for (final item in decoded)
        StudentGroup.fromJson(item as Map<String, dynamic>),
    ];
  }

  Map<String, dynamic> _parseObject(http.Response response) {
    _requireSuccess(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The group response must be an object.');
    }
    return decoded;
  }

  void _requireSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GameplayApiException(response.statusCode, _errorMessage(response));
    }
  }

  String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } on FormatException {
      // Fall through to the response body.
    }
    return response.body;
  }

  void close() => _client.close();
}
