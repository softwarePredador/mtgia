import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:server/ai/battle_engine_config.dart';
import 'package:server/battle/interactive_battle_contract.dart';
import 'package:server/battle/interactive_battle_runtime_client.dart';
import 'package:test/test.dart';

void main() {
  test('uses the bounded full-replay transport ceiling', () {
    expect(interactiveBattleMaximumRuntimePayloadBytes, 8 * 1024 * 1024);
  });

  test('accepts one correlated private participant snapshot', () async {
    late http.Request captured;
    final runtime = _runtime((request) async {
      captured = request;
      return _jsonResponse(_snapshot(), 201);
    });

    final snapshot = await runtime.create({
      'request_id': _requestId,
      'request_hash': _requestHash,
    });
    runtime.close();

    expect(captured.method, 'POST');
    expect(captured.url.path, '/interactive/sessions');
    expect(snapshot.runtimeSessionId, _runtimeId);
    expect(snapshot.requestHash, _requestHash);
    expect(snapshot.status, InteractiveBattleStatus.waitingForAction);
    expect(snapshot.prompt?.options.single.id, _optionId);
    expect(snapshot.privateState['own_hand'], hasLength(1));
  });

  test(
    'parses bounded accepted-action receipts without public payloads',
    () async {
      final response = _snapshot();
      response['accepted_action_receipts'] = [
        {
          'schema_version': interactiveBattleActionReceiptSchema,
          'action_id': 'accepted-action-1',
          'request_fingerprint': 'b' * 64,
          'kind': 'response',
          'accepted_state_version': 4,
        },
      ];
      final runtime = _runtime((_) async => _jsonResponse(response, 200));

      final snapshot = await runtime.read(_runtimeId);
      runtime.close();

      expect(snapshot.acceptedActionReceipts, hasLength(1));
      final receipt = snapshot.acceptedActionReceipts!.single;
      expect(receipt.actionId, 'accepted-action-1');
      expect(receipt.requestFingerprint, 'b' * 64);
      expect(receipt.kind, 'response');
      expect(receipt.acceptedStateVersion, 4);
    },
  );

  test(
    'new receipt protocol must acknowledge the current POST action',
    () async {
      final action = InteractiveBattleActionInput(
        stateVersion: 4,
        promptId: _promptId,
        responseKind: InteractiveBattleResponseKind.option,
        optionId: _optionId,
        idempotencyKey: 'expected-action-1',
      );
      final response =
          _snapshot()..['accepted_action_receipts'] = <Map<String, dynamic>>[];
      final runtime = _runtime((_) async => _jsonResponse(response, 200));

      await expectLater(
        runtime.respond(_runtimeId, action),
        throwsA(
          isA<InteractiveBattleRuntimeException>().having(
            (error) => error.code,
            'code',
            'runtime_action_receipt_rejected',
          ),
        ),
      );
      runtime.close();
    },
  );

  test(
    'accepts the current POST receipt with the exact canonical hash',
    () async {
      final action = InteractiveBattleActionInput(
        stateVersion: 4,
        promptId: _promptId,
        responseKind: InteractiveBattleResponseKind.option,
        optionId: _optionId,
        idempotencyKey: 'accepted-action-current',
      );
      late Map<String, dynamic> posted;
      final runtime = _runtime((request) async {
        posted = jsonDecode(request.body) as Map<String, dynamic>;
        final response = _snapshot();
        response['accepted_action_receipts'] = [
          {
            'schema_version': interactiveBattleActionReceiptSchema,
            'action_id': action.idempotencyKey,
            'request_fingerprint': action.requestFingerprint,
            'kind': 'response',
            'accepted_state_version': action.stateVersion,
          },
        ];
        return _jsonResponse(response, 200);
      });

      final snapshot = await runtime.respond(_runtimeId, action);
      runtime.close();

      expect(posted, action.responsePayload);
      expect(
        snapshot.acceptedActionReceipts!.single.actionId,
        action.idempotencyKey,
      );
    },
  );

  test(
    'rejects duplicate, malformed, or future receipts fail closed',
    () async {
      final valid = {
        'schema_version': interactiveBattleActionReceiptSchema,
        'action_id': 'accepted-action-1',
        'request_fingerprint': 'b' * 64,
        'kind': 'response',
        'accepted_state_version': 4,
      };
      final fixtures = <List<Map<String, dynamic>>>[
        [valid, Map<String, dynamic>.from(valid)],
        [Map<String, dynamic>.from(valid)..['request_fingerprint'] = 'nope'],
        [Map<String, dynamic>.from(valid)..['kind'] = 'private_payload'],
        [Map<String, dynamic>.from(valid)..['accepted_state_version'] = 5],
        [
          Map<String, dynamic>.from(valid)..['private_state'] = {'hand': []},
        ],
      ];

      for (final receipts in fixtures) {
        final response = _snapshot()..['accepted_action_receipts'] = receipts;
        final runtime = _runtime((_) async => _jsonResponse(response, 200));
        await expectLater(
          runtime.read(_runtimeId),
          throwsA(
            isA<InteractiveBattleRuntimeException>().having(
              (error) => error.code,
              'code',
              'runtime_action_receipts_invalid',
            ),
          ),
        );
        runtime.close();
      }
    },
  );

  test(
    'rejects request hash mismatch and malformed process identity',
    () async {
      for (final fixture in [
        (
          _snapshot()..['request_hash'] = 'f' * 64,
          'runtime_correlation_rejected',
        ),
        (_snapshot()..['sidecar_process_id'] = '', 'runtime_identity_rejected'),
      ]) {
        final runtime = _runtime((_) async => _jsonResponse(fixture.$1, 201));
        await expectLater(
          runtime.create({
            'request_id': _requestId,
            'request_hash': _requestHash,
          }),
          throwsA(
            isA<InteractiveBattleRuntimeException>().having(
              (error) => error.code,
              'code',
              fixture.$2,
            ),
          ),
        );
        runtime.close();
      }
    },
  );

  test('rejects opponent hand identity before it reaches the API', () async {
    final leaked = _snapshot();
    (leaked['private_state'] as Map<String, dynamic>)['opponent'] = {
      'hand': ['Secret card'],
    };
    final runtime = _runtime((_) async => _jsonResponse(leaked, 200));

    await expectLater(
      runtime.read(_runtimeId),
      throwsA(
        isA<InteractiveBattleRuntimeException>().having(
          (error) => error.code,
          'code',
          'runtime_private_state_leak_rejected',
        ),
      ),
    );
    runtime.close();
  });

  test('accepts a terminal replay with exact nested identity', () async {
    final runtime = _runtime(
      (_) async => _jsonResponse(_terminalSnapshot(), 200),
    );

    final snapshot = await runtime.read(_runtimeId);

    expect(snapshot.status, InteractiveBattleStatus.conceded);
    expect(snapshot.publicReplay?['engine'], 'xmage');
    expect(
      snapshot.publicReplay?['engine_patch_commit'],
      pinnedXmagePatchCommit,
    );
    runtime.close();
  });

  test('rejects divergent or missing nested replay identity', () async {
    final mutations = <(String, Object?, bool)>[
      ('engine', 'forge', false),
      ('engine_version', '0.0.0', false),
      ('engine_commit', 'f' * 40, false),
      ('engine_patch_commit', 'e' * 40, false),
      ('engine_patch_commit', null, true),
      ('ai_profile', 'computer_easy', false),
      ('ai_profile', null, true),
    ];

    for (final mutation in mutations) {
      final response = _terminalSnapshot();
      final replay = response['public_replay'] as Map<String, dynamic>;
      if (mutation.$3) {
        replay.remove(mutation.$1);
      } else {
        replay[mutation.$1] = mutation.$2;
      }
      final runtime = _runtime((_) async => _jsonResponse(response, 200));

      await expectLater(
        runtime.read(_runtimeId),
        throwsA(
          isA<InteractiveBattleRuntimeException>().having(
            (error) => error.code,
            'code',
            'runtime_replay_identity_rejected',
          ),
        ),
        reason: 'mutation of ${mutation.$1} must fail closed',
      );
      runtime.close();
    }
  });

  test('rejects divergent or missing nested replay correlation', () async {
    final mutations = <(String, Object?, bool)>[
      ('request_schema_version', 'interactive_battle_request_v0', false),
      ('request_schema_version', null, true),
      ('request_id', 'interactive-request-other', false),
      ('request_id', null, true),
      ('request_hash', 'f' * 64, false),
      ('request_hash', null, true),
    ];

    for (final mutation in mutations) {
      final response = _terminalSnapshot();
      final replay = response['public_replay'] as Map<String, dynamic>;
      if (mutation.$3) {
        replay.remove(mutation.$1);
      } else {
        replay[mutation.$1] = mutation.$2;
      }

      await _expectReplayRejected(
        response,
        reason: 'mutation of ${mutation.$1} must fail closed',
      );
    }
  });

  test('rejects arbitrary learning flags, seeds, and schema', () async {
    final mutations = <(String, void Function(Map<String, dynamic> replay))>[
      ('missing contract', (replay) => replay.remove('learning_contract')),
      (
        'wrong schema',
        (replay) =>
            (replay['learning_contract'] as Map)['schema_version'] =
                'external_battle_learning_v0',
      ),
      (
        'named draw claim',
        (replay) =>
            (replay['learning_contract']
                    as Map)['named_draw_identity_available'] =
                true,
      ),
      (
        'arbitrary seed semantics',
        (replay) =>
            (replay['learning_contract'] as Map)['seed_semantics'] =
                'caller_controls_engine_rng',
      ),
      (
        'determinism claim',
        (replay) =>
            (replay['learning_contract'] as Map)['deterministic'] = true,
      ),
      (
        'absence claim',
        (replay) =>
            (replay['learning_contract'] as Map)['absence_proves_nonuse'] =
                true,
      ),
      (
        'strategy claim',
        (replay) =>
            (replay['learning_contract'] as Map)['strategy_or_swap_proof'] =
                true,
      ),
      (
        'unexpected seed',
        (replay) => (replay['learning_contract'] as Map)['seed'] = 424242,
      ),
    ];

    for (final mutation in mutations) {
      final response = _terminalSnapshot();
      mutation.$2(response['public_replay'] as Map<String, dynamic>);

      await _expectReplayRejected(response, reason: mutation.$1);
    }
  });

  test('maps stale and missing runtime responses fail closed', () async {
    for (final fixture in [
      (409, {'error': 'action_stale'}, 'runtime_action_stale', false),
      (404, {'error': 'session_not_found'}, 'runtime_session_not_found', true),
    ]) {
      final runtime = _runtime(
        (_) async => _jsonResponse(fixture.$2, fixture.$1),
      );
      await expectLater(
        runtime.read(_runtimeId),
        throwsA(
          isA<InteractiveBattleRuntimeException>()
              .having((error) => error.code, 'code', fixture.$3)
              .having((error) => error.processLost, 'processLost', fixture.$4),
        ),
      );
      runtime.close();
    }
  });

  test(
    'treats a transport interruption as retryable without losing the session',
    () async {
      final runtime = _runtime(
        (_) async => throw http.ClientException('connection reset'),
      );

      await expectLater(
        runtime.read(_runtimeId),
        throwsA(
          isA<InteractiveBattleRuntimeException>()
              .having((error) => error.code, 'code', 'runtime_transport_failed')
              .having((error) => error.retryable, 'retryable', isTrue)
              .having((error) => error.processLost, 'processLost', isFalse),
        ),
      );
      runtime.close();
    },
  );

  test('configuration requires a dedicated sidecar when enabled', () {
    expect(
      () => InteractiveBattleConfiguration.fromEnvironment({
        'INTERACTIVE_BATTLE_ENABLED': 'true',
        'XMAGE_SIDECAR_URL': 'http://xmage:8080',
        'XMAGE_INTERACTIVE_SIDECAR_URL': 'http://xmage:8080',
      }),
      throwsA(
        isA<InteractiveBattleConfigurationException>().having(
          (error) => error.code,
          'code',
          'interactive_battle_runtime_not_isolated',
        ),
      ),
    );

    final disabled = InteractiveBattleConfiguration.fromEnvironment(const {});
    expect(disabled.enabled, isFalse);
    expect(disabled.maximumActivePerUser, 1);
    expect(disabled.maximumActiveGlobal, 4);
    final enabled = InteractiveBattleConfiguration.fromEnvironment(const {
      'INTERACTIVE_BATTLE_ENABLED': 'true',
      'XMAGE_SIDECAR_URL': 'http://xmage:8080',
      'XMAGE_INTERACTIVE_SIDECAR_URL': 'http://interactive-xmage:8080',
    });
    expect(enabled.enabled, isTrue);
    expect(enabled.identity.patchCommit, pinnedXmagePatchCommit);
    expect(
      enabled.identity.buildIdentity,
      'xmage-sidecar-v2@$pinnedXmageCommit+patch.$pinnedXmagePatchCommit',
    );
    expect(
      interactiveBattleFeatureEnabled({
        'INTERACTIVE_BATTLE_ENABLED': 'true',
        'XMAGE_SIDECAR_URL': 'http://xmage:8080',
        'XMAGE_INTERACTIVE_SIDECAR_URL': 'http://xmage:8080',
      }),
      isFalse,
    );
  });
}

XmageInteractiveBattleRuntime _runtime(
  Future<http.Response> Function(http.Request request) handler,
) => XmageInteractiveBattleRuntime(
  baseUrl: 'http://interactive-xmage:8080',
  expectedIdentity: const ExternalBattleEngineIdentity(
    engine: 'xmage',
    version: pinnedXmageVersion,
    commit: pinnedXmageCommit,
    patchCommit: pinnedXmagePatchCommit,
    aiProfile: 'computer_mad',
    telemetryField: 'normalizer_version',
    telemetryVersion: 'xmage_replay_normalizer_v2',
    seedSemantics: 'request_correlation_only_server_rng_uncontrolled',
    deterministic: false,
  ),
  client: MockClient(handler),
);

Map<String, dynamic> _snapshot() => {
  'schema_version': externalBattleExecutionSchema,
  'status': 'waiting_for_action',
  'engine': 'xmage',
  'engine_version': pinnedXmageVersion,
  'engine_commit': pinnedXmageCommit,
  'engine_patch_commit': pinnedXmagePatchCommit,
  'sidecar_protocol_version': externalBattleSidecarProtocol,
  'sidecar_build_identity':
      'xmage-sidecar-v2@$pinnedXmageCommit+patch.$pinnedXmagePatchCommit',
  'sidecar_process_id': 'process-interactive-1',
  'sidecar_started_at': '2026-07-27T12:00:00Z',
  'ai_profile': 'computer_mad',
  'normalizer_version': 'xmage_replay_normalizer_v2',
  'seed_semantics': 'request_correlation_only_server_rng_uncontrolled',
  'deterministic': false,
  'interactive_schema_version': interactiveBattleRuntimeSchema,
  'runtime_session_id': _runtimeId,
  'request_id': _requestId,
  'request_hash': _requestHash,
  'terminal': false,
  'state_version': 4,
  'last_activity_at': '2026-07-27T12:00:03Z',
  'terminal_reason': null,
  'error_code': null,
  'private_state': {
    'schema_version': interactiveBattlePrivateStateSchema,
    'turn': 1,
    'players': [
      {'name': 'deck_a', 'life': 40, 'hand_size': 7},
      {'name': 'deck_b', 'life': 40, 'hand_size': 7},
    ],
    'own_hand': [
      {'name': 'Plains'},
    ],
  },
  'prompt': {
    'schema_version': interactiveBattlePromptSchema,
    'id': _promptId,
    'state_version': 4,
    'kind': 'mulligan',
    'input_mode': 'options',
    'title': 'Mulligan',
    'message': 'Manter esta mão?',
    'deadline_at': '2026-07-27T12:01:00Z',
    'options': [
      {'id': _optionId, 'label': 'Manter esta mão', 'role': 'keep'},
    ],
  },
};

Map<String, dynamic> _terminalSnapshot() {
  final snapshot = _snapshot();
  snapshot['status'] = 'conceded';
  snapshot['terminal'] = true;
  snapshot['prompt'] = null;
  snapshot['terminal_reason'] = 'user_conceded';
  snapshot['public_replay'] = <String, dynamic>{
    'status': 'conceded',
    'engine': 'xmage',
    'engine_version': pinnedXmageVersion,
    'engine_commit': pinnedXmageCommit,
    'engine_patch_commit': pinnedXmagePatchCommit,
    'ai_profile': 'computer_mad',
    'request_schema_version': interactiveBattleRequestSchema,
    'request_id': _requestId,
    'request_hash': _requestHash,
    'learning_contract': _learningContract(),
    'events': <Map<String, dynamic>>[],
    'visual_snapshots': <Map<String, dynamic>>[],
  };
  return snapshot;
}

Map<String, dynamic> _learningContract() => {
  'schema_version': 'external_battle_learning_v1',
  'named_draw_identity_available': false,
  'visible_stack_activity_available': true,
  'visible_battlefield_entries_available': true,
  'combat_activity_available': true,
  'ai_decision_rationale_available': false,
  'seed_semantics': 'request_correlation_only_server_rng_uncontrolled',
  'deterministic': false,
  'event_stream_completeness': 'best_effort_visible_state_lower_bound',
  'absence_proves_nonuse': false,
  'strategy_or_swap_proof': false,
};

Future<void> _expectReplayRejected(
  Map<String, dynamic> response, {
  required String reason,
}) async {
  final runtime = _runtime((_) async => _jsonResponse(response, 200));
  try {
    await expectLater(
      runtime.read(_runtimeId),
      throwsA(
        isA<InteractiveBattleRuntimeException>().having(
          (error) => error.code,
          'code',
          'runtime_replay_identity_rejected',
        ),
      ),
      reason: reason,
    );
  } finally {
    runtime.close();
  }
}

const _requestId = 'interactive-request-1';
const _requestHash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _runtimeId = 'ibsrt_abcdefghijklmnop';
const _promptId = 'p_abcdefghijklmnop';
const _optionId = 'o_abcdefghijklmnop';

http.Response _jsonResponse(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);
