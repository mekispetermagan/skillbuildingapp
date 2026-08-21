import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/gameplay_api_config.dart';
import '../models/authentication.dart';
import '../models/interface_language.dart';
import 'gameplay_api_client.dart';

abstract interface class AuthenticationApi {
  Future<AuthenticatedAccount> register(AccountRegistration registration);
  Future<AuthenticatedAccount> login(AccountCredentials credentials);
  Future<void> updatePreferredLanguage(
    String accessToken,
    InterfaceLanguage language,
  );
}

class AuthenticationApiClient implements AuthenticationApi {
  final GameplayApiConfig config;
  final http.Client _client;
  final Duration requestTimeout;

  AuthenticationApiClient({
    required this.config,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 5),
  }) : _client = client ?? http.Client();

  @override
  Future<AuthenticatedAccount> register(AccountRegistration registration) =>
      _post('/auth/register', registration.toJson());

  @override
  Future<AuthenticatedAccount> login(AccountCredentials credentials) =>
      _post('/auth/login', credentials.toJson());

  @override
  Future<void> updatePreferredLanguage(
    String accessToken,
    InterfaceLanguage language,
  ) async {
    final response = await _client
        .patch(
          config.endpoint('/auth/preferences'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'X-API-Key': config.apiKey,
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({'preferred_language': language.wireName}),
        )
        .timeout(requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GameplayApiException(response.statusCode, _errorMessage(response));
    }
  }

  Future<AuthenticatedAccount> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await _client
        .post(
          config.endpoint(path),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'X-API-Key': config.apiKey,
          },
          body: jsonEncode(body),
        )
        .timeout(requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GameplayApiException(response.statusCode, _errorMessage(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The API response must be a JSON object.');
    }
    return AuthenticatedAccount.fromJson(decoded);
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
