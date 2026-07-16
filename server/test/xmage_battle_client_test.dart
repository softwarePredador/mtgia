import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:server/ai/xmage_battle_client.dart';
import 'package:test/test.dart';

void main() {
  test('returns a successful XMage battle payload', () async {
    final client = XmageBattleClient(
      baseUrl: 'http://xmage.internal:8080/',
      client: MockClient((request) async {
        expect(request.url.toString(), 'http://xmage.internal:8080/simulate');
        expect(request.headers['content-type'], 'application/json');
        expect(jsonDecode(request.body), containsPair('seed', 42));
        return http.Response(
          jsonEncode({
            'status': 'completed',
            'engine': 'xmage',
            'winner_deck_id': 'deck-a',
            'turns': 7,
          }),
          200,
        );
      }),
    );

    final result = await client.simulate({'seed': 42});

    expect(result['engine'], 'xmage');
    expect(result['winner_deck_id'], 'deck-a');
  });

  test('rejects a zero-turn completed XMage payload', () async {
    final client = XmageBattleClient(
      baseUrl: 'http://xmage.internal:8080',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 'completed',
            'engine': 'xmage',
            'turns': 0,
            'events': <dynamic>[],
            'visual_snapshots': <dynamic>[],
          }),
          200,
        ),
      ),
    );

    await expectLater(
      client.simulate({'seed': 42}),
      throwsA(
        isA<XmageServiceException>().having(
          (error) => error.statusCode,
          'status',
          502,
        ),
      ),
    );
  });

  test('rejects mismatched-engine and error-bearing XMage payloads', () async {
    final invalidPayloads = [
      {'status': 'completed', 'engine': 'forge', 'turns': 7},
      {
        'status': 'completed',
        'engine': 'xmage',
        'turns': 7,
        'error': 'engine_failed',
      },
    ];

    for (final payload in invalidPayloads) {
      final client = XmageBattleClient(
        baseUrl: 'http://xmage.internal:8080',
        client: MockClient(
          (_) async => http.Response(jsonEncode(payload), 200),
        ),
      );
      await expectLater(
        client.simulate({'seed': 42}),
        throwsA(
          isA<XmageServiceException>().having(
            (error) => error.statusCode,
            'status',
            502,
          ),
        ),
      );
      client.close();
    }
  });

  test('exposes unsupported cards from the strict sidecar contract', () async {
    final client = XmageBattleClient(
      baseUrl: 'http://xmage.internal:8080',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': 'xmage_coverage_incomplete',
            'message': 'XMage could not resolve 1 card entries',
            'unsupported_cards': [
              {'deck_key': 'deck_a', 'name': 'Molecule Man'},
            ],
          }),
          422,
        ),
      ),
    );

    await expectLater(
      client.simulate({'seed': 42}),
      throwsA(
        isA<XmageCoverageIncomplete>().having(
          (error) => error.unsupportedCards.single['name'],
          'unsupported card',
          'Molecule Man',
        ),
      ),
    );
  });

  test('does not reinterpret sidecar failures as valid battles', () async {
    final client = XmageBattleClient(
      baseUrl: 'http://xmage.internal:8080',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'error': 'simulation_failed', 'message': 'offline'}),
          500,
        ),
      ),
    );

    await expectLater(
      client.simulate({'seed': 42}),
      throwsA(
        isA<XmageServiceException>().having(
          (error) => error.statusCode,
          'status',
          500,
        ),
      ),
    );
  });

  test('classifies a client deadline as gateway timeout', () async {
    final client = XmageBattleClient(
      baseUrl: 'http://xmage.internal:8080',
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      client.simulate({'seed': 42}),
      throwsA(
        isA<XmageServiceException>().having(
          (error) => error.statusCode,
          'status',
          504,
        ),
      ),
    );
  });
}
