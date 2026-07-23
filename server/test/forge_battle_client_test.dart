import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:server/ai/battle_engine_config.dart';
import 'package:server/ai/forge_battle_client.dart';
import 'package:test/test.dart';

const _identity = ExternalBattleEngineIdentity(
  engine: 'forge',
  version: pinnedForgeVersion,
  commit: pinnedForgeCommit,
  aiProfile: 'forge_default_ai',
  telemetryField: 'parser_version',
  telemetryVersion: 'forge_log_parser_v2',
  seedSemantics: 'engine_rng_seeded_not_replay_guarantee',
  deterministic: false,
);

void main() {
  test('returns a successful Forge battle payload', () async {
    final client = ForgeBattleClient(
      baseUrl: 'http://forge.internal:8080/',
      expectedIdentity: _identity,
      allowLegacyIdentity: true,
      client: MockClient((request) async {
        expect(request.url.toString(), 'http://forge.internal:8080/simulate');
        expect(jsonDecode(request.body), containsPair('seed', 42));
        return http.Response(
          jsonEncode({
            'status': 'completed',
            'engine': 'forge',
            'winner_deck_id': 'deck-a',
            'turns': 7,
          }),
          200,
        );
      }),
    );

    final result = await client.simulate({'seed': 42});

    expect(result['engine'], 'forge');
    expect(result['winner_deck_id'], 'deck-a');
  });

  test('rejects a zero-turn completed Forge payload', () async {
    final client = ForgeBattleClient(
      baseUrl: 'http://forge.internal:8080',
      expectedIdentity: _identity,
      allowLegacyIdentity: true,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'status': 'completed', 'engine': 'forge', 'turns': 0}),
          200,
        ),
      ),
    );

    await expectLater(
      client.simulate({'seed': 42}),
      throwsA(
        isA<ForgeServiceException>().having(
          (error) => error.statusCode,
          'status',
          502,
        ),
      ),
    );
  });

  test('rejects mismatched-engine and error-bearing Forge payloads', () async {
    final invalidPayloads = [
      {'status': 'completed', 'engine': 'xmage', 'turns': 7},
      {
        'status': 'completed',
        'engine': 'forge',
        'turns': 7,
        'error': 'engine_failed',
      },
    ];

    for (final payload in invalidPayloads) {
      final client = ForgeBattleClient(
        baseUrl: 'http://forge.internal:8080',
        expectedIdentity: _identity,
        allowLegacyIdentity: true,
        client: MockClient(
          (_) async => http.Response(jsonEncode(payload), 200),
        ),
      );
      await expectLater(
        client.simulate({'seed': 42}),
        throwsA(
          isA<ForgeServiceException>().having(
            (error) => error.statusCode,
            'status',
            502,
          ),
        ),
      );
      client.close();
    }
  });

  test('exposes unsupported cards from the strict Forge contract', () async {
    final client = ForgeBattleClient(
      baseUrl: 'http://forge.internal:8080',
      expectedIdentity: _identity,
      allowLegacyIdentity: true,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': 'forge_coverage_incomplete',
            'message': 'Forge could not resolve one card',
            'unsupported_cards': [
              {'deck': 'deck_a', 'name': 'Unknown Card'},
            ],
          }),
          422,
        ),
      ),
    );

    await expectLater(
      client.simulate({'seed': 42}),
      throwsA(
        isA<ForgeCoverageIncomplete>().having(
          (error) => error.unsupportedCards.single['name'],
          'unsupported card',
          'Unknown Card',
        ),
      ),
    );
  });

  test('does not reinterpret Forge process failures as battles', () async {
    final client = ForgeBattleClient(
      baseUrl: 'http://forge.internal:8080',
      expectedIdentity: _identity,
      allowLegacyIdentity: true,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': 'simulation_failed',
            'message': 'Forge returned no completed game result',
          }),
          500,
        ),
      ),
    );

    await expectLater(
      client.simulate({'seed': 42}),
      throwsA(
        isA<ForgeServiceException>().having(
          (error) => error.statusCode,
          'status',
          500,
        ),
      ),
    );
  });

  test('classifies a client deadline as gateway timeout', () async {
    final client = ForgeBattleClient(
      baseUrl: 'http://forge.internal:8080',
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
        isA<ForgeServiceException>().having(
          (error) => error.statusCode,
          'status',
          504,
        ),
      ),
    );
  });

  test('validates strict Forge identity, request hash and seed', () async {
    final request = _strictRequest(_identity);
    final client = ForgeBattleClient(
      baseUrl: 'http://forge.internal:8080',
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
  });

  test('rejects Forge identity and request-correlation mismatches', () async {
    final request = _strictRequest(_identity);
    final wrongCommit = _strictResponse(request, _identity, turns: 7)
      ..['engine_commit'] = '0000000000000000000000000000000000000000';
    final commitClient = ForgeBattleClient(
      baseUrl: 'http://forge.internal:8080',
      expectedIdentity: _identity,
      client: MockClient(
        (_) async => http.Response(jsonEncode(wrongCommit), 422),
      ),
    );
    await expectLater(
      commitClient.simulate(request),
      throwsA(isA<ForgeServiceException>()),
    );

    final wrongHash = _strictResponse(request, _identity, turns: 7)
      ..['request_hash'] = 'wrong';
    final hashClient = ForgeBattleClient(
      baseUrl: 'http://forge.internal:8080',
      expectedIdentity: _identity,
      client: MockClient(
        (_) async => http.Response(jsonEncode(wrongHash), 200),
      ),
    );
    await expectLater(
      hashClient.simulate(request),
      throwsA(isA<ForgeServiceException>()),
    );
  });

  test(
    'accepts censored Forge output without winner and preserves timeout',
    () async {
      final censoredRequest = _strictRequest(_identity, maxTurns: 3);
      final censoredClient = ForgeBattleClient(
        baseUrl: 'http://forge.internal:8080',
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
      final result = await censoredClient.simulate(censoredRequest);
      expect(result['status'], 'censored');
      expect(result['winner_deck_id'], isNull);

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
      final timeoutClient = ForgeBattleClient(
        baseUrl: 'http://forge.internal:8080',
        expectedIdentity: _identity,
        client: MockClient(
          (_) async => http.Response(jsonEncode(timeoutBody), 504),
        ),
      );
      await expectLater(
        timeoutClient.simulate(timeoutRequest),
        throwsA(
          isA<ForgeServiceException>().having(
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
    'sidecar_process_id': 'forge-process',
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
