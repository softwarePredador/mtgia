import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/battle/models/interactive_battle_session.dart';
import 'package:manaloom/features/battle/services/interactive_battle_service.dart';

class _FakeApiClient extends ApiClient {
  final List<String> getCalls = [];
  final List<String> postCalls = [];
  final List<Map<String, dynamic>> postBodies = [];

  @override
  Future<ApiResponse> get(String endpoint) async {
    getCalls.add(endpoint);
    return ApiResponse(200, _sessionJson());
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    postCalls.add(endpoint);
    postBodies.add(Map<String, dynamic>.from(body));
    return ApiResponse(200, {'accepted': true, 'session': _sessionJson()});
  }
}

void main() {
  test(
    'creates, resumes, responds, and concedes with idempotent payloads',
    () async {
      final api = _FakeApiClient();
      final service = InteractiveBattleService(apiClient: api);

      final created = await service.create(
        deckId: '00000000-0000-4000-8000-000000000001',
        opponentDeckId: '00000000-0000-4000-8000-000000000002',
      );
      final resumed = await service.get(created.id);
      await service.respond(
        sessionId: created.id,
        prompt: created.prompt!,
        response: const InteractiveBattleResponse.option('o_abcdefghijklmnop'),
      );
      await service.concede(created.id);

      expect(resumed.id, created.id);
      expect(api.getCalls, ['/ai/battle/sessions/session-1']);
      expect(api.postCalls, [
        '/ai/battle/sessions',
        '/ai/battle/sessions/session-1/actions',
        '/ai/battle/sessions/session-1/concede',
      ]);
      expect(
        api.postBodies.first['schema_version'],
        'interactive_battle_request_v1',
      );
      expect(
        api.postBodies.first['idempotency_key'],
        startsWith('battle-create:'),
      );
      expect(api.postBodies[1], containsPair('state_version', 7));
      expect(
        api.postBodies[1],
        containsPair('prompt_id', 'p_abcdefghijklmnop'),
      );
      expect(
        api.postBodies[1],
        containsPair('option_id', 'o_abcdefghijklmnop'),
      );
      expect(
        api.postBodies[1]['idempotency_key'],
        startsWith('battle-action:'),
      );
      expect(
        api.postBodies.last['idempotency_key'],
        startsWith('battle-concede:'),
      );
    },
  );

  test('maps disabled backend to a useful fail-closed message', () async {
    final service = InteractiveBattleService(apiClient: _DisabledApiClient());

    await expectLater(
      service.get('missing'),
      throwsA(
        isA<InteractiveBattleGatewayException>().having(
          (error) => error.message,
          'message',
          contains('não está habilitado'),
        ),
      ),
    );
  });

  test('does not expose the runtime vendor returned by the backend', () async {
    final service = InteractiveBattleService(
      apiClient: _VendorErrorApiClient(),
    );

    await expectLater(
      service.get('failed'),
      throwsA(
        isA<InteractiveBattleGatewayException>()
            .having(
              (error) => error.message,
              'message',
              contains('motor de regras'),
            )
            .having(
              (error) => error.message,
              'vendor name',
              isNot(contains('XMage')),
            ),
      ),
    );
  });

  test('reuses the create idempotency key after a lost response', () async {
    final api = _RetryCreateApiClient();
    final service = InteractiveBattleService(apiClient: api);

    await expectLater(
      service.create(
        deckId: '00000000-0000-4000-8000-000000000001',
        opponentDeckId: '00000000-0000-4000-8000-000000000002',
      ),
      throwsStateError,
    );
    final session = await service.create(
      deckId: '00000000-0000-4000-8000-000000000001',
      opponentDeckId: '00000000-0000-4000-8000-000000000002',
    );

    expect(session.id, 'session-1');
    expect(api.idempotencyKeys, hasLength(2));
    expect(api.idempotencyKeys.toSet(), hasLength(1));
  });

  test('reuses action and concede keys after lost responses', () async {
    final api = _RetryMutationApiClient();
    final service = InteractiveBattleService(apiClient: api);
    final session = InteractiveBattleSession.fromJson(_sessionJson());
    final prompt = session.prompt!;

    await expectLater(
      service.respond(
        sessionId: session.id,
        prompt: prompt,
        response: const InteractiveBattleResponse.delegate(),
      ),
      throwsStateError,
    );
    await service.respond(
      sessionId: session.id,
      prompt: prompt,
      response: const InteractiveBattleResponse.delegate(),
    );
    await expectLater(service.concede(session.id), throwsStateError);
    await service.concede(session.id);

    expect(api.actionKeys, hasLength(2));
    expect(api.actionKeys.toSet(), hasLength(1));
    expect(api.concedeKeys, hasLength(2));
    expect(api.concedeKeys.toSet(), hasLength(1));
  });
}

class _DisabledApiClient extends ApiClient {
  @override
  Future<ApiResponse> get(String endpoint) async =>
      ApiResponse(404, {'error': 'interactive_battle_not_found'});
}

class _VendorErrorApiClient extends ApiClient {
  @override
  Future<ApiResponse> get(String endpoint) async => ApiResponse(503, const {
    'error': 'interactive_battle_runtime_unavailable',
    'message': 'XMage interactive connection is not ready',
  });
}

class _RetryCreateApiClient extends ApiClient {
  int attempts = 0;
  final List<String> idempotencyKeys = [];

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    idempotencyKeys.add(body['idempotency_key'] as String);
    attempts += 1;
    if (attempts == 1) throw StateError('response lost');
    return ApiResponse(200, {'created': false, 'session': _sessionJson()});
  }
}

class _RetryMutationApiClient extends ApiClient {
  int actionAttempts = 0;
  int concedeAttempts = 0;
  final List<String> actionKeys = [];
  final List<String> concedeKeys = [];

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    if (endpoint.endsWith('/actions')) {
      actionKeys.add(body['idempotency_key'] as String);
      actionAttempts += 1;
      if (actionAttempts == 1) throw StateError('action response lost');
    } else if (endpoint.endsWith('/concede')) {
      concedeKeys.add(body['idempotency_key'] as String);
      concedeAttempts += 1;
      if (concedeAttempts == 1) throw StateError('concede response lost');
    }
    return ApiResponse(200, {'accepted': true, 'session': _sessionJson()});
  }
}

Map<String, dynamic> _sessionJson() => {
  'schema_version': 'interactive_battle_session_v1',
  'id': 'session-1',
  'status': 'waiting_for_action',
  'state_version': 7,
  'deck_id': '00000000-0000-4000-8000-000000000001',
  'opponent_deck_id': '00000000-0000-4000-8000-000000000002',
  'expires_at': '2026-07-27T15:30:00Z',
  'updated_at': '2026-07-27T15:00:00Z',
  'private_state': {
    'turn': 1,
    'players': const <dynamic>[],
    'stack': const <dynamic>[],
    'combat': const <dynamic>[],
    'own_hand': const <dynamic>[],
  },
  'prompt': {
    'schema_version': 'interactive_battle_prompt_v1',
    'id': 'p_abcdefghijklmnop',
    'state_version': 7,
    'kind': 'mulligan',
    'input_mode': 'options',
    'title': 'Mão inicial',
    'message': 'Manter esta mão?',
    'deadline_at': '2099-07-27T15:01:00Z',
    'options': [
      {'id': 'o_abcdefghijklmnop', 'label': 'Manter esta mão', 'role': 'keep'},
    ],
  },
};
