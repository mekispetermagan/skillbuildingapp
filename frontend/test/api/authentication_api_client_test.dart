import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:skillbuilding_game/api/authentication_api_client.dart';
import 'package:skillbuilding_game/api/gameplay_api_client.dart';
import 'package:skillbuilding_game/config/gameplay_api_config.dart';
import 'package:skillbuilding_game/models/authentication.dart';
import 'package:skillbuilding_game/models/interface_language.dart';

void main() {
  final config = GameplayApiConfig(
    baseUri: Uri.parse('https://example.test/api/'),
    apiKey: 'test-key',
  );

  test('registers an account with the authentication contract', () async {
    late http.Request captured;
    final api = AuthenticationApiClient(
      config: config,
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'account_id': 4,
            'username': 'teacher.one',
            'name': 'Teacher One',
            'role': 'teacher',
            'preferred_language': 'en',
            'location': 'Kampala',
            'age': null,
            'gender': null,
            'access_token': 'server-token',
          }),
          201,
        );
      }),
    );

    final account = await api.register(
      AccountRegistration(
        username: 'Teacher.One',
        pin: '123456',
        name: 'Teacher One',
        role: AccountRole.teacher,
        preferredLanguage: InterfaceLanguage.english,
        location: 'Kampala',
      ),
    );

    expect(captured.url.path, '/api/auth/register');
    expect(captured.headers['X-API-Key'], 'test-key');
    expect(jsonDecode(captured.body), {
      'username': 'teacher.one',
      'pin': '123456',
      'name': 'Teacher One',
      'role': 'teacher',
      'preferred_language': 'en',
      'location': 'Kampala',
      'age': null,
      'gender': null,
    });
    expect(account.accountId, 4);
    expect(account.role, AccountRole.teacher);
  });

  test('logs in and reports rejected credentials', () async {
    final api = AuthenticationApiClient(
      config: config,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'detail': 'Invalid username or PIN.'}),
          401,
        ),
      ),
    );

    expect(
      () => api.login(AccountCredentials(username: 'learner', pin: '000000')),
      throwsA(
        isA<GameplayApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
  });
}
