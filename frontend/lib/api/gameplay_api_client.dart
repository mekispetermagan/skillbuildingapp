import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/gameplay_api_config.dart';
import '../models/record_sync.dart';

class GameplayApiException implements Exception {
  final int statusCode;
  final String message;

  const GameplayApiException(this.statusCode, this.message);

  @override
  String toString() => 'GameplayApiException($statusCode, $message)';
}

class UnknownInstallationException extends GameplayApiException {
  const UnknownInstallationException(String message) : super(404, message);
}

abstract interface class GameplayApi {
  Future<InstallationRegistration> resolveInstallation(int? installationId);
  Future<RecordBatchAcknowledgement> submit(
    RecordBatch batch, {
    String? accessToken,
  });
}

class GameplayApiClient implements GameplayApi {
  final GameplayApiConfig config;
  final http.Client _client;
  final Duration requestTimeout;

  GameplayApiClient({
    required this.config,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 5),
  }) : _client = client ?? http.Client();

  @override
  Future<InstallationRegistration> resolveInstallation(
    int? installationId,
  ) async {
    final response = await _post(
      '/installations',
      InstallationResolution(installationId: installationId).toJson(),
    );
    if (response.statusCode == 404 && installationId != null) {
      throw UnknownInstallationException(_errorMessage(response));
    }
    _requireSuccess(response);
    return InstallationRegistration.fromJson(_jsonObject(response));
  }

  @override
  Future<RecordBatchAcknowledgement> submit(
    RecordBatch batch, {
    String? accessToken,
  }) async {
    final response = await _post(
      '/records/batch',
      batch.toJson(),
      accessToken: accessToken,
    );
    if (response.statusCode == 404) {
      throw UnknownInstallationException(_errorMessage(response));
    }
    _requireSuccess(response);
    return RecordBatchAcknowledgement.fromJson(_jsonObject(response));
  }

  Future<http.Response> _post(
    String path,
    Object body, {
    String? accessToken,
  }) => _client
      .post(
        config.endpoint(path),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-API-Key': config.apiKey,
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      )
      .timeout(requestTimeout);

  void _requireSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GameplayApiException(response.statusCode, _errorMessage(response));
    }
  }

  Map<String, dynamic> _jsonObject(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The API response must be a JSON object.');
    }
    return decoded;
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
