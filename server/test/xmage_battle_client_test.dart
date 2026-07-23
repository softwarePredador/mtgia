import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:server/ai/battle_engine_config.dart';
import 'package:server/ai/xmage_battle_client.dart';
import 'package:test/test.dart';

const _identity = ExternalBattleEngineIdentity(
  engine: 'xmage',
  version: pinnedXmageVersion,
  commit: pinnedXmageCommit,
  aiProfile: 'computer_mad',
  telemetryField: 'normalizer_version',
  telemetryVersion: 'xmage_replay_normalizer_v2',
  seedSemantics: 'request_correlation_only_server_rng_uncontrolled',
  deterministic: false,
);

void main() {
  test('returns a successful XMage battle payload', () async {
    final client = XmageBattleClient(
      baseUrl: 'http://xmage.internal:8080/',
      expectedIdentity: _identity,
      allowLegacyIdentity: true,
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
      expectedIdentity: _identity,
      allowLegacyIdentity: true,
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
        expectedIdentity: _identity,
        allowLegacyIdentity: true,
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
      expectedIdentity: _identity,
      allowLegacyIdentity: true,
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
      expectedIdentity: _identity,
      allowLegacyIdentity: true,
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
      expectedIdentity: _identity,
      allowLegacyIdentity: true,
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

  test(
    'validates the strict identity, request hash and returned seed',
    () async {
      final request = _strictRequest(_identity);
      final client = XmageBattleClient(
        baseUrl: 'http://xmage.internal:8080',
        expectedIdentity: _identity,
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(_strictResponse(request, _identity, turns: 7)),
            200,
          ),
        ),
      );

      final result = await client.simulate(request);

      expect(result['seed'], 42);
      expect(result['request_hash'], request['request_hash']);
      expect(result['status'], 'completed');
    },
  );

  test(
    'rejects a commit mismatch before accepting a coverage fallback',
    () async {
      final request = _strictRequest(_identity);
      final body =
          _strictResponse(request, _identity, turns: 7)
            ..['engine_commit'] = '0000000000000000000000000000000000000000'
            ..['error'] = 'xmage_coverage_incomplete';
      final client = XmageBattleClient(
        baseUrl: 'http://xmage.internal:8080',
        expectedIdentity: _identity,
        client: MockClient((_) async => http.Response(jsonEncode(body), 422)),
      );

      await expectLater(
        client.simulate(request),
        throwsA(
          isA<XmageServiceException>()
              .having((error) => error.statusCode, 'status', 502)
              .having((error) => error.message, 'message', contains('commit')),
        ),
      );
    },
  );

  test(
    'rejects a returned seed that differs from the submitted request',
    () async {
      final request = _strictRequest(_identity);
      final body = _strictResponse(request, _identity, turns: 7)..['seed'] = 43;
      final client = XmageBattleClient(
        baseUrl: 'http://xmage.internal:8080',
        expectedIdentity: _identity,
        client: MockClient((_) async => http.Response(jsonEncode(body), 200)),
      );

      await expectLater(
        client.simulate(request),
        throwsA(
          isA<XmageServiceException>()
              .having((error) => error.statusCode, 'status', 502)
              .having((error) => error.message, 'message', contains('seed')),
        ),
      );
    },
  );

  test('rejects any stronger XMage determinism claim', () async {
    final request = _strictRequest(_identity);
    final body =
        _strictResponse(request, _identity, turns: 7)
          ..['seed_semantics'] = 'engine_random_seed'
          ..['deterministic'] = true;
    final client = XmageBattleClient(
      baseUrl: 'http://xmage.internal:8080',
      expectedIdentity: _identity,
      client: MockClient((_) async => http.Response(jsonEncode(body), 200)),
    );

    await expectLater(
      client.simulate(request),
      throwsA(
        isA<XmageServiceException>()
            .having((error) => error.statusCode, 'status', 502)
            .having(
              (error) => error.message,
              'message',
              contains('seed semantics'),
            ),
      ),
    );
  });

  test(
    'accepts explicit max-turn censoring and rejects timeout as success',
    () async {
      final censoredRequest = _strictRequest(_identity, maxTurns: 3);
      final censoredClient = XmageBattleClient(
        baseUrl: 'http://xmage.internal:8080',
        expectedIdentity: _identity,
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(
              _strictResponse(
                censoredRequest,
                _identity,
                turns: 7,
                status: 'censored',
              ),
            ),
            200,
          ),
        ),
      );
      final censoredResult = await censoredClient.simulate(censoredRequest);
      expect(censoredResult['status'], 'censored');
      expect(censoredResult['winner_deck_id'], isNull);

      final leakedWinnerBody = _strictResponse(
        censoredRequest,
        _identity,
        turns: 7,
        status: 'censored',
      )..['winner_deck_id'] = 'deck-a';
      final leakedWinnerClient = XmageBattleClient(
        baseUrl: 'http://xmage.internal:8080',
        expectedIdentity: _identity,
        client: MockClient(
          (_) async => http.Response(jsonEncode(leakedWinnerBody), 200),
        ),
      );
      await expectLater(
        leakedWinnerClient.simulate(censoredRequest),
        throwsA(isA<XmageServiceException>()),
      );

      final timeoutRequest = _strictRequest(_identity);
      final timeoutBody =
          _strictResponse(timeoutRequest, _identity, turns: 7)
            ..['error'] = 'simulation_timeout'
            ..['fallback_reason'] = 'none'
            ..['fallback_eligibility_reason'] =
                'operational_timeout_not_eligible'
            ..['execution_outcome'] = {
              'status': 'timeout',
              'timed_out': true,
              'censored': true,
              'censor_reason': 'wall_clock_timeout',
              'timeout_ms': timeoutRequest['timeout_ms'],
            };
      final timeoutClient = XmageBattleClient(
        baseUrl: 'http://xmage.internal:8080',
        expectedIdentity: _identity,
        client: MockClient(
          (_) async => http.Response(jsonEncode(timeoutBody), 504),
        ),
      );
      await expectLater(
        timeoutClient.simulate(timeoutRequest),
        throwsA(
          isA<XmageServiceException>().having(
            (error) => error.statusCode,
            'status',
            504,
          ),
        ),
      );
    },
  );
}

Map<String, dynamic> _strictRequest(
  ExternalBattleEngineIdentity identity, {
  int maxTurns = 30,
}) => buildExternalBattleRequestEnvelope(
  identity: identity,
  request: {
    'request_id': 'request-42',
    'seed': 42,
    'timeout_ms': 40000,
    'max_turns': maxTurns,
    'focus_cards': const ['Sol Ring'],
    'force_focus_access_mode': 'none',
    'same_lane': true,
    'natural_sample': true,
    'deck_a': _deck('deck-a'),
    'deck_b': _deck('deck-b'),
  },
);

Map<String, dynamic> _deck(String id) => {
  'id': id,
  'name': id,
  'cards': const [
    {'name': 'Commander', 'quantity': 1, 'is_commander': true},
    {'name': 'Plains', 'quantity': 99, 'is_commander': false},
  ],
};

Map<String, dynamic> _strictResponse(
  Map<String, dynamic> request,
  ExternalBattleEngineIdentity identity, {
  required int turns,
  String status = 'completed',
}) {
  final censored = status == 'censored';
  return {
    'schema_version': externalBattleExecutionSchema,
    'status': status,
    'engine': identity.engine,
    'engine_version': identity.version,
    'engine_commit': identity.commit,
    'sidecar_protocol_version': externalBattleSidecarProtocol,
    'sidecar_build_identity': identity.buildIdentity,
    'sidecar_process_id': 'xmage-process',
    'sidecar_started_at': '2026-07-22T12:00:00Z',
    'ai_profile': identity.aiProfile,
    identity.telemetryField: identity.telemetryVersion,
    'seed_semantics': identity.seedSemantics,
    'deterministic': identity.deterministic,
    'request_id': request['request_id'],
    'seed': request['seed'],
    'timeout_ms': request['timeout_ms'],
    'request_hash': request['request_hash'],
    'deck_hashes': request['deck_hashes'],
    'fallback_reason': 'none',
    'turns': turns,
    'request_contract': {
      'schema_version': externalBattleRequestSchema,
      'controls': {
        'max_turns': {'value': request['max_turns']},
        'focus_cards': {'value': request['focus_cards']},
        'force_focus_access_mode': {
          'value': request['force_focus_access_mode'],
        },
        'same_lane': {'value': request['same_lane']},
        'natural_sample': {'value': request['natural_sample']},
      },
    },
    'execution_outcome': {
      'status': status,
      'timed_out': false,
      'censored': censored,
      'censor_reason': censored ? 'max_turns_exceeded' : null,
      'timeout_ms': request['timeout_ms'],
      'turns': turns,
    },
  };
}
