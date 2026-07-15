import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import '../lib/ai/native_battle_client.dart';

void main() {
  test('returns a reviewed native battle result', () async {
    final client = NativeBattleClient(
      baseUrl: 'http://native:8080',
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'status': 'completed',
            'engine': 'manaloom_native_reviewed',
            'engine_contract': 'native_reviewed_rules_execution',
          }),
          200,
          headers: const {'content-type': 'application/json'},
        ),
      ),
    );

    final result = await client.simulate(const {'request_id': 'test'});
    expect(result['engine'], 'manaloom_native_reviewed');
    client.close();
  });

  test('preserves structured native coverage failures', () async {
    final client = NativeBattleClient(
      baseUrl: 'http://native:8080',
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'error': 'native_coverage_incomplete',
            'unsupported_cards': [
              {'name': 'Unknown Card'},
            ],
          }),
          422,
        ),
      ),
    );

    expect(
      () => client.simulate(const {'request_id': 'test'}),
      throwsA(
        isA<NativeBattleCoverageIncomplete>().having(
          (error) => error.unsupportedCards.single['name'],
          'unsupported card',
          'Unknown Card',
        ),
      ),
    );
    client.close();
  });

  test('maps service failures without falling back silently', () async {
    final client = NativeBattleClient(
      baseUrl: 'http://native:8080',
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({'error': 'native_runtime_failed'}),
          500,
        ),
      ),
    );

    expect(
      () => client.simulate(const {'request_id': 'test'}),
      throwsA(
        isA<NativeBattleServiceException>().having(
          (error) => error.statusCode,
          'status',
          500,
        ),
      ),
    );
    client.close();
  });

  test('rejects a successful response with an untrusted engine contract',
      () async {
    final client = NativeBattleClient(
      baseUrl: 'http://native.test',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 'completed',
            'engine': 'manaloom_native_legacy',
            'engine_contract': 'experimental_advisory',
          }),
          200,
        ),
      ),
    );

    await expectLater(
      client.simulate(const {'required_rule_cards': []}),
      throwsA(
        isA<NativeBattleServiceException>().having(
          (error) => error.message,
          'message',
          contains('untrusted engine contract'),
        ),
      ),
    );
  });
}
