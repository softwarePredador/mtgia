import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:server/ai/battle_engine_config.dart';
import 'package:server/battle/interactive_battle_contract.dart';
import 'package:server/battle/interactive_battle_runtime_client.dart';
import 'package:test/test.dart';

void main() {
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
  'sidecar_protocol_version': externalBattleSidecarProtocol,
  'sidecar_build_identity': 'xmage-sidecar-v2@$pinnedXmageCommit',
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
