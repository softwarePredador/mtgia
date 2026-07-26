import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/battle/models/battle_job.dart';
import 'package:manaloom/features/battle/models/battle_test_setup.dart';
import 'package:manaloom/features/battle/services/battle_job_gateway.dart';

class _FakeApiClient extends ApiClient {
  final Map<String, List<ApiResponse>> responses = {};
  final List<String> getCalls = [];
  final List<String> postCalls = [];
  final List<String> deleteCalls = [];
  final List<Map<String, dynamic>> postBodies = [];

  void enqueue(String method, String endpoint, ApiResponse response) {
    responses.putIfAbsent('$method $endpoint', () => []).add(response);
  }

  ApiResponse _take(String method, String endpoint) {
    final queue = responses['$method $endpoint'];
    if (queue == null || queue.isEmpty) {
      throw StateError('No response for $method $endpoint');
    }
    return queue.removeAt(0);
  }

  @override
  Future<ApiResponse> get(String endpoint) async {
    getCalls.add(endpoint);
    return _take('GET', endpoint);
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    postCalls.add(endpoint);
    postBodies.add(Map<String, dynamic>.from(body));
    return _take('POST', endpoint);
  }

  @override
  Future<ApiResponse> delete(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    deleteCalls.add(endpoint);
    return _take('DELETE', endpoint);
  }
}

void main() {
  group('BattleJobGateway lifecycle', () {
    test('creates with idempotency and BattleTestSetup payload', () async {
      final api = _FakeApiClient()
        ..enqueue(
          'POST',
          '/ai/battle/jobs',
          ApiResponse(201, {'created': true, 'job': _jobJson()}),
        );
      final gateway = BattleJobGateway(apiClient: api);
      final request = BattleJobCreateRequest(
        deckId: 'deck-a',
        setup: BattleTestSetup(
          opponentDeckId: 'deck-b',
          objective: BattleTestObjective.commander,
          focusCards: const ['Krenko, Mob Boss'],
        ),
        idempotencyKey: 'attempt-1',
      );

      final creation = await gateway.create(request);

      expect(creation.created, isTrue);
      expect(creation.job.status, BattleJobStatus.queued);
      expect(api.postCalls, ['/ai/battle/jobs']);
      expect(api.postBodies.single, {
        'schema_version': 'battle_job_v1',
        'deck_id': 'deck-a',
        'opponent_deck_id': 'deck-b',
        'test_objective': 'commander',
        'focus_cards': const ['Krenko, Mob Boss'],
        'max_turns': 30,
        'timeout_ms': 40000,
        'idempotency_key': 'attempt-1',
      });
    });

    test('lists, gets and cancels through the canonical endpoints', () async {
      final api = _FakeApiClient()
        ..enqueue(
          'GET',
          '/ai/battle/jobs?limit=10&status=running&deck_id=deck-a',
          ApiResponse(200, {
            'schema_version': 'battle_job_list_v1',
            'jobs': [_jobJson(status: 'running', stage: 'running')],
          }),
        )
        ..enqueue(
          'GET',
          '/ai/battle/jobs/job-1',
          ApiResponse(200, _jobJson(status: 'running', stage: 'running')),
        )
        ..enqueue(
          'DELETE',
          '/ai/battle/jobs/job-1',
          ApiResponse(202, {
            'accepted': true,
            'job': _jobJson(
              status: 'cancel_pending',
              stage: 'cancel_pending',
              cancelPending: true,
            ),
          }),
        );
      final gateway = BattleJobGateway(apiClient: api);

      final listed = await gateway.list(
        limit: 10,
        status: BattleJobStatus.running,
        deckId: 'deck-a',
      );
      final fetched = await gateway.get('job-1');
      final cancelled = await gateway.cancel('job-1');

      expect(listed.single.status, BattleJobStatus.running);
      expect(fetched.jobId, 'job-1');
      expect(cancelled.accepted, isTrue);
      expect(cancelled.job.status, BattleJobStatus.cancelPending);
      expect(api.deleteCalls, ['/ai/battle/jobs/job-1']);
    });

    for (final scenario in <(int, String, String)>[
      (409, 'battle_job_conflict', 'raw-conflict-secret'),
      (422, 'battle_job_unprocessable', 'unsupported-private-card'),
      (429, 'battle_job_rate_limited', 'quota-user-internal'),
    ]) {
      test('maps HTTP ${scenario.$1} to a safe message', () async {
        final api = _FakeApiClient()
          ..enqueue(
            'GET',
            '/ai/battle/jobs/job-1',
            ApiResponse(scenario.$1, {
              'error': scenario.$3,
              if (scenario.$1 == 429) 'retry_after_seconds': 12,
            }),
          );

        await expectLater(
          BattleJobGateway(apiClient: api).get('job-1'),
          throwsA(
            isA<BattleJobGatewayException>()
                .having((error) => error.code, 'code', scenario.$2)
                .having(
                  (error) => error.message.contains(scenario.$3),
                  'does not expose raw backend detail',
                  isFalse,
                )
                .having(
                  (error) => error.retryAfterSeconds,
                  'retry after',
                  scenario.$1 == 429 ? 12 : null,
                ),
          ),
        );
      });
    }

    test('rejects a response whose idempotent job changed request', () async {
      final mismatched = _jobJson()..['deck_b_id'] = 'other-deck';
      final api = _FakeApiClient()
        ..enqueue(
          'POST',
          '/ai/battle/jobs',
          ApiResponse(200, {'created': false, 'job': mismatched}),
        );

      await expectLater(
        BattleJobGateway(apiClient: api).create(
          BattleJobCreateRequest(
            deckId: 'deck-a',
            setup: BattleTestSetup(opponentDeckId: 'deck-b'),
            idempotencyKey: 'attempt-1',
          ),
        ),
        throwsA(
          isA<BattleJobGatewayException>().having(
            (error) => error.code,
            'code',
            'invalid_battle_job_response',
          ),
        ),
      );
    });
  });

  group('BattleJobGateway live polling', () {
    test('resends cursor, deduplicates and reaches the final replay', () async {
      final firstRecord = _eventRecord(sequence: 1, recordId: 'event-1');
      final api = _FakeApiClient()
        ..enqueue(
          'GET',
          '/ai/battle/jobs/job-1/live?limit=50',
          ApiResponse(
            200,
            _livePage(items: [firstRecord], nextCursor: 'blc1.first.signature'),
          ),
        )
        ..enqueue(
          'GET',
          '/ai/battle/jobs/job-1/live?limit=50&cursor=blc1.first.signature',
          ApiResponse(
            200,
            _livePage(
              status: 'completed',
              terminal: true,
              terminalReason: 'completed',
              items: [Map<String, dynamic>.from(firstRecord)],
              nextCursor: 'blc1.finished.signature',
              replay: const {'replay_id': 'replay-1', 'available': true},
            ),
          ),
        );
      final gateway = BattleJobGateway(apiClient: api);

      final first = await gateway.pollLive(jobId: 'job-1');
      final completed = await gateway.pollLive(jobId: 'job-1', session: first);

      expect(first.records, hasLength(1));
      expect(completed.records, hasLength(1));
      expect(completed.cursor, 'blc1.finished.signature');
      expect(completed.isTerminal, isTrue);
      expect(completed.replayId, 'replay-1');
      expect(api.getCalls.last, contains('cursor=blc1.first.signature'));
    });

    test('converts a private-zone payload into a safe contract failure', () {
      final leaked = _snapshotRecord(sequence: 1, recordId: 'snapshot-1');
      final snapshot = leaked['snapshot'] as Map<String, dynamic>;
      final players = snapshot['players'] as List<dynamic>;
      (players.last as Map<String, dynamic>)['library'] = ['Hidden Card'];
      final api = _FakeApiClient()
        ..enqueue(
          'GET',
          '/ai/battle/jobs/job-1/live?limit=50',
          ApiResponse(200, _livePage(items: [leaked])),
        );

      expectLater(
        BattleJobGateway(apiClient: api).pollLive(jobId: 'job-1'),
        throwsA(
          isA<BattleJobGatewayException>().having(
            (error) => error.code,
            'code',
            'invalid_battle_live_response',
          ),
        ),
      );
    });
  });
}

Map<String, dynamic> _jobJson({
  String status = 'queued',
  String stage = 'queued',
  bool cancelPending = false,
}) {
  return <String, dynamic>{
    'schema_version': 'battle_job_v1',
    'job_id': 'job-1',
    'idempotency_key': 'attempt-1',
    'status': status,
    'stage': stage,
    'progress': const {'current': 0, 'total': 6, 'ratio': 0.0},
    'deck_a_id': 'deck-a',
    'deck_b_id': 'deck-b',
    'deck_hashes': {
      'schema_version': 'external_battle_deck_hash_v1',
      'algorithm': 'sha256',
      'deck_a': _hash('a'),
      'deck_b': _hash('b'),
    },
    'request_schema_version': 'external_battle_request_v2',
    'request_hash': _hash('c'),
    'requested_engine': 'auto',
    'engine': null,
    'timeout_ms': 40000,
    'attempt_count': 0,
    if (cancelPending) 'cancel_requested_at': '2026-07-26T12:00:01Z',
    'heartbeat_at': '2026-07-26T12:00:01Z',
    'created_at': '2026-07-26T12:00:00Z',
    'updated_at': '2026-07-26T12:00:01Z',
    'can_cancel':
        status == 'queued' || status == 'claimed' || status == 'running',
    'can_resume': true,
    'poll_url': '/ai/battle/jobs/job-1',
    'cancel_url': '/ai/battle/jobs/job-1',
  };
}

Map<String, dynamic> _livePage({
  String status = 'running',
  bool terminal = false,
  String? terminalReason,
  List<Map<String, dynamic>> items = const [],
  String nextCursor = 'blc1.next.signature',
  Map<String, dynamic>? replay,
}) {
  return <String, dynamic>{
    'schema_version': 'battle_live_cursor_v1',
    'transport': 'polling_long_polling',
    'stream_id': 'job-1',
    'status': status,
    'is_terminal': terminal,
    if (terminalReason != null) 'terminal_reason': terminalReason,
    'items': items,
    'item_count': items.length,
    'next_cursor': nextCursor,
    'has_more': false,
    'truncated': false,
    'truncation': const {
      'source': false,
      'page_limit': false,
      'payload_limit': false,
      'field_limit': false,
    },
    'limits': const {'page': 50, 'payload_bytes': 131072},
    'replay_pending': false,
    'replay_already_delivered': false,
    if (replay != null) 'replay': replay,
  };
}

Map<String, dynamic> _eventRecord({
  required int sequence,
  required String recordId,
}) {
  return <String, dynamic>{
    'schema_version': 'battle_live_cursor_v1',
    'cursor': 'blc1.event$sequence.signature',
    'sequence': sequence,
    'record_id': recordId,
    'kind': 'event',
    'event': {
      'event_type': 'spell_cast',
      'event_id': recordId,
      'turn': 1,
      'actor_side': 'deck_a',
      'subject_deck_key': 'deck_a',
      'card_name': 'Sol Ring',
    },
    'content_truncated': false,
  };
}

Map<String, dynamic> _snapshotRecord({
  required int sequence,
  required String recordId,
}) {
  return <String, dynamic>{
    'schema_version': 'battle_live_cursor_v1',
    'cursor': 'blc1.snapshot$sequence.signature',
    'sequence': sequence,
    'record_id': recordId,
    'kind': 'snapshot',
    'snapshot': {
      'snapshot_id': recordId,
      'index': sequence,
      'turn': 1,
      'players': [
        {'deck_key': 'deck_a', 'life': 40, 'hand_size': 7},
        {'deck_key': 'deck_b', 'life': 40, 'hand_size': 7},
      ],
    },
    'content_truncated': false,
  };
}

String _hash(String character) => List.filled(64, character).join();
