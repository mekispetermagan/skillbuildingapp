import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:skillbuilding_game/api/gameplay_api_client.dart';
import 'package:skillbuilding_game/config/gameplay_api_config.dart';
import 'package:skillbuilding_game/models/activity_id.dart';
import 'package:skillbuilding_game/models/feature_metrics.dart';
import 'package:skillbuilding_game/models/learning_area.dart';
import 'package:skillbuilding_game/models/play_outcome.dart';
import 'package:skillbuilding_game/models/play_record.dart';
import 'package:skillbuilding_game/models/record_sync.dart';

void main() {
  final config = GameplayApiConfig(
    baseUri: Uri.parse('https://example.test/api/'),
    apiKey: 'test-key',
  );

  test('uses localhost by default for development', () {
    final environmentConfig = GameplayApiConfig.fromEnvironment();

    expect(environmentConfig.baseUri.toString(), 'http://localhost:8000');
    expect(environmentConfig.apiKey, 'dev-key');
  });

  test(
    'resolves a nullable installation with the configured API key',
    () async {
      late http.Request captured;
      final api = GameplayApiClient(
        config: config,
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({'installation_id': 4, 'next_record_number': 7}),
            201,
          );
        }),
      );

      final registration = await api.resolveInstallation(null);

      expect(captured.url.toString(), 'https://example.test/api/installations');
      expect(captured.headers['X-API-Key'], 'test-key');
      expect(jsonDecode(captured.body), {'installation_id': null});
      expect(registration.installationId, 4);
      expect(registration.nextRecordNumber, 7);
    },
  );

  test('submits record batches and parses acknowledgements', () async {
    final api = GameplayApiClient(
      config: config,
      client: MockClient((request) async {
        expect(request.url.path, '/api/records/batch');
        return http.Response(
          jsonEncode({
            'installation_id': 4,
            'next_record_number': 2,
            'acknowledgements': [
              {'record_number': 1, 'status': 'accepted'},
            ],
          }),
          200,
        );
      }),
    );
    final record = PlayRecord(
      installationId: 4,
      recordNumber: 1,
      area: LearningArea.literacy,
      feature: ActivityId.phraseBuilding,
      outcome: PlayOutcome.won,
      score: 10,
      rating: 5,
      metrics: AttemptMetrics(correctAnswers: 10, incorrectAttempts: 1),
      startedAt: DateTime.utc(2026, 8, 16, 10),
      completedAt: DateTime.utc(2026, 8, 16, 10, 2),
      elapsedMilliseconds: 120000,
      appVersion: '0.1.0+1',
      contentVersion: 'en-1',
    );

    final result = await api.submit(
      RecordBatch(installationId: 4, records: [record]),
    );

    expect(result.nextRecordNumber, 2);
    expect(result.acknowledgements.single.recordNumber, 1);
  });

  test('reports an unknown installation distinctly', () async {
    final api = GameplayApiClient(
      config: config,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'detail': 'Installation does not exist.'}),
          404,
        ),
      ),
    );

    expect(
      () => api.resolveInstallation(99),
      throwsA(isA<UnknownInstallationException>()),
    );
  });
}
