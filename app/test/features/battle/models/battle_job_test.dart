import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/battle/models/battle_job.dart';
import 'package:manaloom/features/battle/models/battle_test_setup.dart';

void main() {
  group('BattleJobCreateRequest', () {
    test('serializes the canonical BattleTestSetup payload', () {
      final request = BattleJobCreateRequest(
        deckId: 'deck-a',
        setup: BattleTestSetup(
          opponentDeckId: ' deck-b ',
          objective: BattleTestObjective.focusCards,
          focusCards: const [' Sol Ring ', 'Arcane Signet'],
        ),
        idempotencyKey: 'battle-attempt-001',
        maxTurns: 42,
        timeoutMs: 35000,
        engine: BattleRequestedEngine.xmage,
        seed: 1234,
      );

      expect(request.toJson(), {
        'schema_version': 'battle_job_v1',
        'deck_id': 'deck-a',
        'opponent_deck_id': 'deck-b',
        'test_objective': 'focus_cards',
        'focus_cards': const ['Sol Ring', 'Arcane Signet'],
        'max_turns': 42,
        'timeout_ms': 35000,
        'engine': 'xmage',
        'seed': 1234,
        'idempotency_key': 'battle-attempt-001',
      });
    });

    test('rejects invalid limits before any HTTP request', () {
      expect(
        () => BattleJobCreateRequest(
          deckId: 'deck-a',
          setup: BattleTestSetup(opponentDeckId: 'deck-b'),
          idempotencyKey: 'attempt',
          maxTurns: 101,
        ),
        throwsA(
          isA<BattleJobContractException>().having(
            (error) => error.code,
            'code',
            'invalid_max_turns',
          ),
        ),
      );
    });

    test('rejects an empty focus objective and a self-match', () {
      expect(
        () => BattleJobCreateRequest(
          deckId: 'deck-a',
          setup: BattleTestSetup(
            opponentDeckId: 'deck-b',
            objective: BattleTestObjective.focusCards,
          ),
          idempotencyKey: 'attempt',
        ),
        throwsA(
          isA<BattleJobContractException>().having(
            (error) => error.code,
            'code',
            'focus_cards_required',
          ),
        ),
      );
      expect(
        () => BattleJobCreateRequest(
          deckId: 'deck-a',
          setup: BattleTestSetup(opponentDeckId: 'deck-a'),
          idempotencyKey: 'attempt',
        ),
        throwsA(
          isA<BattleJobContractException>().having(
            (error) => error.code,
            'code',
            'battle_job_same_deck',
          ),
        ),
      );
    });
  });

  group('BattleJob', () {
    test('parses active job without manufacturing an outcome', () {
      final job = BattleJob.fromJson(_jobJson());

      expect(job.status, BattleJobStatus.queued);
      expect(job.outcome, isNull);
      expect(job.progress.current, 0);
      expect(job.progress.total, 6);
      expect(job.canCancel, isTrue);
      expect(job.replayId, isNull);
    });

    test('derives a completed outcome only from a terminal status', () {
      final job = BattleJob.fromJson(
        _jobJson(
          status: 'completed',
          stage: 'completed',
          progress: const {'current': 6, 'total': 6, 'ratio': 1.0},
          terminal: true,
          replayId: 'replay-1',
          engine: true,
        ),
      );

      expect(job.isTerminal, isTrue);
      expect(job.outcome, BattleJobOutcome.completed);
      expect(job.replayId, 'replay-1');
      expect(job.engine, BattleExecutionEngine.xmage);
      expect(job.canCancel, isFalse);
    });

    test('rejects an unknown status and mismatched progress ratio', () {
      expect(
        () => BattleJob.fromJson(_jobJson(status: 'done')),
        throwsA(
          isA<BattleJobContractException>().having(
            (error) => error.code,
            'code',
            'invalid_status',
          ),
        ),
      );

      expect(
        () => BattleJob.fromJson(
          _jobJson(progress: const {'current': 1, 'total': 4, 'ratio': 0.75}),
        ),
        throwsA(
          isA<BattleJobContractException>().having(
            (error) => error.code,
            'code',
            'progress_ratio_mismatch',
          ),
        ),
      );
    });

    test(
      'rejects status, stage, cancellation and timeline inconsistencies',
      () {
        expect(
          () => BattleJob.fromJson(
            _jobJson(status: 'running', stage: 'completed'),
          ),
          throwsA(
            isA<BattleJobContractException>().having(
              (error) => error.code,
              'code',
              'stage_status_mismatch',
            ),
          ),
        );

        final invalidCancel = _jobJson()..['can_cancel'] = false;
        expect(
          () => BattleJob.fromJson(invalidCancel),
          throwsA(
            isA<BattleJobContractException>().having(
              (error) => error.code,
              'code',
              'can_cancel_status_mismatch',
            ),
          ),
        );

        final falseCompletion = _jobJson(
          status: 'completed',
          stage: 'completed',
          progress: const {'current': 6, 'total': 6, 'ratio': 1.0},
          terminal: true,
          engine: true,
        );
        expect(
          () => BattleJob.fromJson(falseCompletion),
          throwsA(
            isA<BattleJobContractException>().having(
              (error) => error.code,
              'code',
              'completed_job_missing_replay',
            ),
          ),
        );
      },
    );

    test('fails closed for schema drift and unlisted public fields', () {
      final wrongSchema = _jobJson()..['schema_version'] = 'battle_job_v2';
      expect(
        () => BattleJob.fromJson(wrongSchema),
        throwsA(
          isA<BattleJobContractException>().having(
            (error) => error.code,
            'code',
            'unsupported_schema_version',
          ),
        ),
      );

      final leakedInternal = _jobJson()..['lease_token'] = 'private-token';
      expect(
        () => BattleJob.fromJson(leakedInternal),
        throwsA(
          isA<BattleJobContractException>().having(
            (error) => error.code,
            'code',
            'unknown_job_field',
          ),
        ),
      );
    });
  });

  group('BattleJobList', () {
    test('validates list schema and duplicate job identity', () {
      final first = _jobJson();
      final duplicate = Map<String, dynamic>.from(first);
      expect(
        () => BattleJobList.fromJson({
          'schema_version': 'battle_job_list_v1',
          'jobs': [first, duplicate],
        }),
        throwsA(
          isA<BattleJobContractException>().having(
            (error) => error.code,
            'code',
            'duplicate_job_id',
          ),
        ),
      );
    });
  });
}

Map<String, dynamic> _jobJson({
  String status = 'queued',
  String stage = 'queued',
  Map<String, dynamic> progress = const {
    'current': 0,
    'total': 6,
    'ratio': 0.0,
  },
  bool terminal = false,
  String? replayId,
  bool engine = false,
}) {
  return <String, dynamic>{
    'schema_version': 'battle_job_v1',
    'job_id': 'job-1',
    'idempotency_key': 'attempt-1',
    'status': status,
    'stage': stage,
    'progress': progress,
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
    if (engine) ...{
      'engine': 'xmage',
      'engine_version': '1.4.56',
      'engine_commit': 'commit-1',
      'engine_build': 'build-1',
      'engine_process_id': 'process-1',
      'engine_process_started_at': '2026-07-26T12:00:01Z',
    } else
      'engine': null,
    'timeout_ms': 40000,
    'attempt_count': engine ? 1 : 0,
    if (engine) 'attempt_id': 'attempt-engine-1',
    if (replayId != null) 'replay_id': replayId,
    if (terminal) 'terminal_reason': status,
    'heartbeat_at': '2026-07-26T12:00:02Z',
    'created_at': '2026-07-26T12:00:00Z',
    'updated_at': terminal ? '2026-07-26T12:00:05Z' : '2026-07-26T12:00:02Z',
    if (terminal) 'finished_at': '2026-07-26T12:00:05Z',
    'can_cancel': !terminal && status != 'cancel_pending',
    'can_resume': !terminal,
    'poll_url': '/ai/battle/jobs/job-1',
    'cancel_url': '/ai/battle/jobs/job-1',
  };
}

String _hash(String character) => List.filled(64, character).join();
