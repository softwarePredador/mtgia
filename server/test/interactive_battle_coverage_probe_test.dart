import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:server/ai/battle_engine_config.dart';
import 'package:server/battle/interactive_battle_contract.dart';
import 'package:server/battle/interactive_battle_coverage_probe.dart';
import 'package:test/test.dart';

void main() {
  test('rejects a reused batch runtime before any coverage request', () {
    expect(
      () => InteractiveBattleCoverageClient(
        batchBaseUrl: 'http://shared.internal',
        interactiveBaseUrl: 'http://shared.internal/',
        expectedIdentity: _identity,
        expectedInteractiveMaximumActive: 4,
        client: MockClient((_) async => http.Response('{}', 500)),
      ),
      throwsA(
        isA<InteractiveBattleCoverageException>().having(
          (error) => error.code,
          'code',
          'interactive_runtime_not_isolated',
        ),
      ),
    );
  });

  test(
    'proves exact deck coverage against the isolated interactive catalog',
    () async {
      final requested = <String>[];
      final client = _client((request) async {
        requested.add('${request.method} ${request.url}');
        if (request.url.host == 'batch.internal' &&
            request.url.path == '/health') {
          return _json(_health(processId: 'batch-process', batch: true));
        }
        if (request.url.host == 'interactive.internal' &&
            request.url.path == '/health') {
          return _json(_health(processId: 'interactive-process', batch: false));
        }
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect((body['deck_a'] as Map)['id'], 'deck-a');
        expect((body['deck_b'] as Map)['id'], 'deck-b');
        return _json(
          _coverage(
            processId:
                request.url.host == 'batch.internal'
                    ? 'batch-process'
                    : 'interactive-process',
          ),
        );
      });

      final result = await client.check(deckA: _deckA, deckB: _deckB);

      expect(result.ready, isTrue);
      expect(result.unsupportedCards, isEmpty);
      expect(requested, [
        'GET http://batch.internal/health',
        'GET http://interactive.internal/health',
        'POST http://batch.internal/coverage',
        'POST http://interactive.internal/coverage',
      ]);
      client.close();
    },
  );

  test('rejects divergent dedicated runtime card coverage', () async {
    final client = _client((request) async {
      if (request.url.host == 'batch.internal' &&
          request.url.path == '/health') {
        return _json(_health(processId: 'batch-process', batch: true));
      }
      if (request.url.host == 'interactive.internal') {
        return _json(
          _health(processId: 'interactive-process', batch: false)
            ..['indexed_names'] = 15999,
        );
      }
      return _json(_coverage(processId: 'batch-process'));
    });

    await expectLater(
      client.check(deckA: _deckA, deckB: _deckB),
      throwsA(
        isA<InteractiveBattleCoverageException>().having(
          (error) => error.code,
          'code',
          'interactive_coverage_catalog_mismatch',
        ),
      ),
    );
    client.close();
  });

  test('rejects a deck-specific coverage result mismatch', () async {
    final client = _client((request) async {
      final interactive = request.url.host == 'interactive.internal';
      if (request.url.path == '/health') {
        return _json(
          _health(
            processId: interactive ? 'interactive-process' : 'batch-process',
            batch: !interactive,
          ),
        );
      }
      if (interactive) {
        return _json(_coverage(processId: 'interactive-process', ready: false));
      }
      return _json(_coverage(processId: 'batch-process'));
    });

    await expectLater(
      client.check(deckA: _deckA, deckB: _deckB),
      throwsA(
        isA<InteractiveBattleCoverageException>().having(
          (error) => error.code,
          'code',
          'interactive_coverage_result_mismatch',
        ),
      ),
    );
    client.close();
  });

  test('fails closed when the dedicated runtime is unavailable', () async {
    final client = _client((request) async {
      if (request.url.host == 'batch.internal') {
        return _json(_health(processId: 'batch-process', batch: true));
      }
      return http.Response('{}', 503);
    });

    await expectLater(
      client.check(deckA: _deckA, deckB: _deckB),
      throwsA(
        isA<InteractiveBattleCoverageException>()
            .having(
              (error) => error.code,
              'code',
              'interactive_coverage_unavailable',
            )
            .having((error) => error.statusCode, 'statusCode', 503)
            .having((error) => error.retryable, 'retryable', isTrue),
      ),
    );
    client.close();
  });

  test('rejects pin or process correlation divergence', () async {
    Future<void> expectRejected({required bool corruptPin}) async {
      final client = _client((request) async {
        if (request.url.host == 'batch.internal' &&
            request.url.path == '/health') {
          return _json(_health(processId: 'batch-process', batch: true));
        }
        if (request.url.host == 'interactive.internal') {
          final health = _health(
            processId: 'interactive-process',
            batch: false,
          );
          if (corruptPin) health['engine_commit'] = 'f' * 40;
          return _json(health);
        }
        return _json(
          _coverage(processId: corruptPin ? 'batch-process' : 'stale-process'),
        );
      });

      await expectLater(
        client.check(deckA: _deckA, deckB: _deckB),
        throwsA(
          isA<InteractiveBattleCoverageException>().having(
            (error) => error.code,
            'code',
            corruptPin
                ? 'interactive_coverage_identity_rejected'
                : 'interactive_coverage_correlation_rejected',
          ),
        ),
      );
      client.close();
    }

    await expectRejected(corruptPin: true);
    await expectRejected(corruptPin: false);
  });
}

InteractiveBattleCoverageClient _client(
  Future<http.Response> Function(http.Request request) handler,
) => InteractiveBattleCoverageClient(
  batchBaseUrl: 'http://batch.internal',
  interactiveBaseUrl: 'http://interactive.internal',
  expectedIdentity: _identity,
  expectedInteractiveMaximumActive: 4,
  client: MockClient(handler),
);

http.Response _json(Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), 200);

Map<String, dynamic> _health({
  required String processId,
  required bool batch,
}) => {
  ..._identityPayload(processId),
  'status': 'ok',
  'catalog_ready': true,
  'indexed_names': 16000,
  'card_qualification_policy_commit': pinnedXmageCommit,
  'card_qualification_restrictions': 3,
  'card_activation_policy_schema': 'activation-policy-v1',
  'card_activation_restrictions': 21,
  'pin_transition_card_inventory': 145,
  'card_activation_postgresql_evidence_sha256': 'a' * 64,
  'card_activation_postgresql_rows_sha256': 'b' * 64,
  'future_card_activation_restrictions': 8,
  'released_missing_card_activation_restrictions': 13,
  'runtime_mode': batch ? 'batch' : 'interactive',
  'batch_simulation_available': batch,
  if (!batch)
    'interactive_battle': {
      'schema_version': interactiveBattleRuntimeSchema,
      'maximum_active': 4,
      'active': 0,
      'retained': 0,
      'runtime_mode': 'interactive',
      'batch_simulation_available': false,
    },
};

Map<String, dynamic> _coverage({
  required String processId,
  bool ready = true,
}) => {
  ..._identityPayload(processId),
  'status': ready ? 'ready' : 'unsupported',
  'ready': ready,
  'decks': [
    const {'deck_key': 'deck_a', 'deck_id': 'deck-a', 'ready': true},
    {'deck_key': 'deck_b', 'deck_id': 'deck-b', 'ready': ready},
  ],
  'unsupported_cards':
      ready
          ? const <Map<String, dynamic>>[]
          : const [
            {
              'deck_key': 'deck_b',
              'name': 'Missing Card',
              'set_code': 'TST',
              'collector_number': '9',
              'quantity': 1,
              'is_commander': false,
            },
          ],
};

Map<String, dynamic> _identityPayload(String processId) => {
  'schema_version': externalBattleExecutionSchema,
  'engine': 'xmage',
  'engine_version': pinnedXmageVersion,
  'engine_commit': pinnedXmageCommit,
  'engine_patch_commit': pinnedXmagePatchCommit,
  'sidecar_protocol_version': externalBattleSidecarProtocol,
  'sidecar_build_identity': _identity.buildIdentity,
  'sidecar_process_id': processId,
  'sidecar_started_at': '2026-08-02T12:00:00Z',
  'ai_profile': 'computer_mad',
  'normalizer_version': 'xmage_replay_normalizer_v2',
  'seed_semantics': 'request_correlation_only_server_rng_uncontrolled',
  'deterministic': false,
};

const _identity = ExternalBattleEngineIdentity(
  engine: 'xmage',
  version: pinnedXmageVersion,
  commit: pinnedXmageCommit,
  patchCommit: pinnedXmagePatchCommit,
  aiProfile: 'computer_mad',
  telemetryField: 'normalizer_version',
  telemetryVersion: 'xmage_replay_normalizer_v2',
  seedSemantics: 'request_correlation_only_server_rng_uncontrolled',
  deterministic: false,
);

const _deckA = <String, dynamic>{
  'id': 'deck-a',
  'name': 'Deck A',
  'cards': <Map<String, dynamic>>[],
};
const _deckB = <String, dynamic>{
  'id': 'deck-b',
  'name': 'Deck B',
  'cards': <Map<String, dynamic>>[],
};
