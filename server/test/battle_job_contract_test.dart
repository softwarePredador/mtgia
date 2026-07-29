import 'package:server/battle/battle_job_contract.dart';
import 'package:server/battle/battle_request_correlation.dart';
import 'package:server/battle/battle_job_service.dart';
import 'package:test/test.dart';

const _deckA = '11111111-1111-4111-8111-111111111111';
const _deckB = '22222222-2222-4222-8222-222222222222';

void main() {
  group('battle_job_v1 request', () {
    test('parses the closed request and matching idempotency aliases', () {
      final input = BattleJobCreateInput.parse({
        'schema_version': battleJobSchemaVersion,
        'type': 'battle',
        'deck_id': _deckA.toUpperCase(),
        'opponent_deck_id': _deckB,
        'engine': 'native',
        'timeout_ms': 12000,
        'max_turns': 25,
        'seed': 42,
        'test_objective': 'focus_cards',
        'focus_cards': ['Sol Ring', 'Arcane Signet'],
        'force_focus_access_mode': 'opening_hand',
        'same_lane': true,
        'natural_sample': false,
        'request_key': 'battle-contract-1',
      }, headerIdempotencyKey: 'battle-contract-1');

      expect(input.deckId, _deckA);
      expect(input.opponentDeckId, _deckB);
      expect(input.requestedEngine, 'native');
      expect(input.timeoutMs, 12000);
      expect(input.maxTurns, 25);
      expect(input.seed, 42);
      expect(input.focusCards, ['Sol Ring', 'Arcane Signet']);
      expect(input.forceFocusAccessMode, 'opening_hand');
      expect(input.sameLane, isTrue);
      expect(input.naturalSample, isFalse);
      expect(input.idempotencyKey, 'battle-contract-1');
    });

    test('rejects invalid UUIDs and unknown fields', () {
      expect(
        () => BattleJobCreateInput.parse({
          'deck_id': 'not-a-uuid',
          'opponent_deck_id': _deckB,
        }),
        throwsA(
          isA<BattleJobValidationException>().having(
            (error) => error.code,
            'code',
            'battle_job_deck_id_invalid',
          ),
        ),
      );
      expect(
        () => BattleJobCreateInput.parse({
          'deck_id': _deckA,
          'opponent_deck_id': _deckB,
          'surprise': true,
        }),
        throwsA(
          isA<BattleJobValidationException>().having(
            (error) => error.code,
            'code',
            'battle_job_unknown_field',
          ),
        ),
      );
    });

    test('keeps invalid execution-mode copy vendor neutral', () {
      expect(
        () => BattleJobCreateInput.parse({
          'deck_id': _deckA,
          'opponent_deck_id': _deckB,
          'engine': 'old-runner',
        }),
        throwsA(
          isA<BattleJobValidationException>()
              .having(
                (error) => error.code,
                'code',
                'battle_job_engine_invalid',
              )
              .having(
                (error) => error.message,
                'message',
                isNot(anyOf(contains('xmage'), contains('forge'))),
              ),
        ),
      );
    });

    test('rejects external forced draws and more than three focus cards', () {
      expect(
        () => BattleJobCreateInput.parse({
          'deck_id': _deckA,
          'opponent_deck_id': _deckB,
          'engine': 'xmage',
          'force_focus_access_mode': 'library_top',
        }),
        throwsA(
          isA<BattleJobValidationException>().having(
            (error) => error.code,
            'code',
            'external_battle_control_unsupported',
          ),
        ),
      );
      expect(
        () => BattleJobCreateInput.parse({
          'deck_id': _deckA,
          'opponent_deck_id': _deckB,
          'focus_cards': ['A', 'B', 'C', 'D'],
        }),
        throwsA(
          isA<BattleJobValidationException>().having(
            (error) => error.code,
            'code',
            'battle_job_focus_cards_invalid',
          ),
        ),
      );
    });

    test('rejects disagreeing idempotency keys', () {
      expect(
        () => BattleJobCreateInput.parse({
          'deck_id': _deckA,
          'opponent_deck_id': _deckB,
          'idempotency_key': 'body-key',
        }, headerIdempotencyKey: 'header-key'),
        throwsA(
          isA<BattleJobValidationException>().having(
            (error) => error.code,
            'code',
            'battle_job_idempotency_mismatch',
          ),
        ),
      );
    });
  });

  test('status set is closed and terminal semantics are explicit', () {
    expect(BattleJobStatus.values.map((status) => status.value), [
      'queued',
      'claimed',
      'running',
      'cancel_pending',
      'completed',
      'censored',
      'timeout',
      'coverage_error',
      'engine_error',
      'cancelled',
      'persistence_error',
    ]);
    expect(BattleJobStatus.queued.isTerminal, isFalse);
    expect(BattleJobStatus.cancelPending.canCancel, isFalse);
    expect(BattleJobStatus.completed.isTerminal, isTrue);
    expect(BattleJobStatus.persistenceError.isTerminal, isTrue);
  });

  test('public job JSON omits owner, frozen payload, and fencing secrets', () {
    final json = _job().toJson();

    expect(json['schema_version'], battleJobSchemaVersion);
    expect(json['job_id'], '33333333-3333-4333-8333-333333333333');
    expect(json['status'], 'running');
    expect(json['can_cancel'], isTrue);
    expect(json['poll_url'], contains('/ai/battle/jobs/'));
    expect(json, isNot(contains('user_id')));
    expect(json, isNot(contains('request_payload')));
    expect(json, isNot(contains('request_fingerprint')));
    expect(json, isNot(contains('lease_owner')));
    expect(json, isNot(contains('lease_token')));
  });

  group('battle job list query', () {
    test('parses owner-list filters', () {
      final filter = parseBattleJobListFilter({
        'limit': '10',
        'status': 'cancel_pending',
        'deck_id': _deckA.toUpperCase(),
      });

      expect(filter.limit, 10);
      expect(filter.status, BattleJobStatus.cancelPending);
      expect(filter.deckId, _deckA);
    });

    test('rejects an unknown status or query key', () {
      expect(
        () => parseBattleJobListFilter({'status': 'success'}),
        throwsA(isA<BattleJobValidationException>()),
      );
      expect(
        () => parseBattleJobListFilter({'cursor': 'opaque'}),
        throwsA(isA<BattleJobValidationException>()),
      );
    });
  });
}

BattleJob _job() {
  final now = DateTime.utc(2026, 7, 26, 12);
  return BattleJob(
    id: '33333333-3333-4333-8333-333333333333',
    userId: '44444444-4444-4444-8444-444444444444',
    status: BattleJobStatus.running,
    stage: 'running',
    progressCurrent: 25,
    progressTotal: 100,
    deckAId: _deckA,
    deckBId: _deckB,
    deckHashSchema: 'external_battle_deck_hash_v1',
    deckAHash: 'a' * 64,
    deckBHash: 'b' * 64,
    requestSchemaVersion: battleJobRequestSchema,
    requestHash: 'c' * 64,
    requestPayload: const {'private': 'frozen deck payload'},
    requestedEngine: 'native',
    engineLane: 'native',
    timeoutMs: 12000,
    attemptCount: 1,
    idempotencyKey: 'battle-contract-1',
    requestFingerprint: 'd' * 64,
    heartbeatAt: now,
    leaseExpiresAt: now.add(const Duration(seconds: 30)),
    createdAt: now,
    updatedAt: now,
  );
}
