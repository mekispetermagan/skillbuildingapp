import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:skillbuilding_game/api/student_group_api_client.dart';
import 'package:skillbuilding_game/config/gameplay_api_config.dart';
import 'package:skillbuilding_game/models/student_group.dart';

void main() {
  final config = GameplayApiConfig(
    baseUri: Uri.parse('https://example.test/api/'),
    apiKey: 'test-key',
  );

  test('synchronizes groups and memberships with authorization', () async {
    late http.Request captured;
    final api = StudentGroupApiClient(
      config: config,
      client: MockClient((request) async {
        captured = request;
        final submitted = jsonDecode(request.body) as Map<String, dynamic>;
        final group = (submitted['groups'] as List<dynamic>).single;
        return http.Response(
          jsonEncode([
            {...group, 'owner_account_id': 2, 'is_owner': true},
          ]),
          200,
        );
      }),
    );
    final group = StudentGroup(
      id: 'group-1',
      name: 'Group One',
      studentIds: const ['student-1'],
      ownerAccountId: 2,
      isOwner: true,
    );

    final result = await api.synchronize('account-token', [group]);

    expect(captured.url.path, '/api/groups/sync');
    expect(captured.headers['Authorization'], 'Bearer account-token');
    expect(jsonDecode(captured.body), {
      'groups': [group.toJson()],
    });
    expect(result.single.studentIds, ['student-1']);
  });

  test('generates a share code and joins a shared group', () async {
    final requests = <http.Request>[];
    final api = StudentGroupApiClient(
      config: config,
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/share-code')) {
          return http.Response(jsonEncode({'code': 'ABCD2345'}), 200);
        }
        return http.Response(
          jsonEncode({
            'client_id': 'shared-group',
            'name': 'Shared Group',
            'student_client_ids': ['student-1'],
            'owner_account_id': 3,
            'is_owner': false,
          }),
          200,
        );
      }),
    );

    final code = await api.generateShareCode('token', 'shared-group');
    final joined = await api.join('token', code);

    expect(code, 'ABCD2345');
    expect(requests.first.url.path, '/api/groups/shared-group/share-code');
    expect(requests.last.url.path, '/api/groups/join');
    expect(jsonDecode(requests.last.body), {'code': 'ABCD2345'});
    expect(joined.isOwner, isFalse);
  });
}
