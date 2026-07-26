@Tags(['live', 'live_db_write'])
library;

import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:server/ai/battle_engine_config.dart';
import 'package:server/ai/native_battle_client.dart';
import 'package:server/battle/battle_execution_runtime.dart';
import 'package:server/battle/battle_job_contract.dart';
import 'package:server/battle/battle_job_executor.dart';
import 'package:server/battle/battle_job_runner.dart';
import 'package:server/battle/battle_job_service.dart';
import 'package:server/battle/battle_job_store.dart';
import 'package:server/battle/battle_request_correlation.dart';
import 'package:server/health_readiness_support.dart';
import 'package:test/test.dart';

const _ownerId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _otherId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const _deckAId = '11111111-1111-4111-8111-111111111111';
const _deckBId = '22222222-2222-4222-8222-222222222222';
const _commanderId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const _mainCardId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
const _commanderScryfallId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
const _mainScryfallId = 'ffffffff-ffff-4fff-8fff-ffffffffffff';

void main() {
  final enabled = Platform.environment['RUN_BATTLE_JOB_DB_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer PostgreSQL descartavel explicitamente isolado.';
  late Pool pool;
  late BattleJobStore store;

  setUpAll(() async {
    if (!enabled) return;
    pool = Pool.withEndpoints([
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME']!,
        username: Platform.environment['DB_USER']!,
        password: Platform.environment['DB_PASS'] ?? '',
      ),
    ], settings: const PoolSettings(sslMode: SslMode.disable));
    store = BattleJobStore(pool);
    await _seed(pool);
  });

  tearDownAll(() async {
    if (enabled) await pool.close();
  });

  test(
    'PostgreSQL closes idempotency, quota, lease, cancel, fencing and replay',
    () async {
      expect((await evaluateReleaseSchemaReadiness(pool)).healthy, isTrue);
      expect((await evaluateBattleJobSchemaReadiness(pool)).healthy, isTrue);

      const quota = BattleJobQuotaPolicy(
        perUserActiveLimit: 1,
        globalActiveLimit: 2,
      );
      final service = BattleJobService(store, quotaPolicy: quota);
      final firstInput = _input('live-idempotent');
      final first = await service.create(userId: _ownerId, input: firstInput);
      final repeated = await service.create(
        userId: _ownerId,
        input: firstInput,
      );

      expect(first.created, isTrue);
      expect(first.job.status, BattleJobStatus.queued);
      expect(repeated.created, isFalse);
      expect(repeated.job.id, first.job.id);
      expect(await store.get(_otherId, first.job.id), isNull);
      expect(await store.get(_ownerId, first.job.id), isNotNull);
      expect(await store.list(_ownerId), hasLength(1));

      await expectLater(
        service.create(
          userId: _ownerId,
          input: _input('live-idempotent', maxTurns: 31),
        ),
        throwsA(isA<BattleJobIdempotencyConflictException>()),
      );
      await expectLater(
        service.create(userId: _ownerId, input: _input('quota-overflow')),
        throwsA(
          isA<BattleJobQuotaExceededException>()
              .having((error) => error.scope, 'scope', 'user')
              .having((error) => error.limit, 'limit', 1),
        ),
      );

      final firstCancelled = await service.cancel(_ownerId, first.job.id);
      expect(firstCancelled.job.status, BattleJobStatus.cancelled);

      final running = await service.create(
        userId: _ownerId,
        input: _input('running-cancel'),
      );
      final runningClaim = await store.claimNext(workerId: 'worker-live');
      expect(runningClaim?.job.id, running.job.id);
      expect(await store.markRunning(runningClaim!), isTrue);
      final progress = await store.heartbeat(
        runningClaim,
        stage: 'running',
        progressCurrent: 10,
        progressTotal: 100,
      );
      expect(progress.active, isTrue);
      final cancelPending = await service.cancel(_ownerId, running.job.id);
      expect(cancelPending.job.status, BattleJobStatus.cancelPending);
      expect((await store.heartbeat(runningClaim)).cancelRequested, isTrue);
      expect(
        await store.transitionTerminal(
          runningClaim,
          _terminal(running.job, BattleJobStatus.cancelled),
        ),
        isTrue,
      );
      expect(
        await store.transitionTerminal(
          runningClaim,
          _terminal(running.job, BattleJobStatus.cancelled),
        ),
        isFalse,
        reason: 'A released fencing token must never close the job twice.',
      );

      final recoverable = await service.create(
        userId: _ownerId,
        input: _input('claimed-recovery'),
      );
      final oldClaim = await store.claimNext(workerId: 'worker-old');
      expect(oldClaim?.job.id, recoverable.job.id);
      await _expireLease(pool, recoverable.job.id);
      final recovered = await store.claimNext(workerId: 'worker-new');
      expect(recovered?.job.id, recoverable.job.id);
      expect(recovered?.job.attemptCount, 2);
      expect(
        await store.transitionTerminal(
          recovered!,
          _terminal(recoverable.job, BattleJobStatus.cancelled),
        ),
        isTrue,
      );
      expect(
        await store.transitionTerminal(
          oldClaim!,
          _terminal(recoverable.job, BattleJobStatus.cancelled),
        ),
        isFalse,
      );

      final expiredRunning = await service.create(
        userId: _ownerId,
        input: _input('running-expiry'),
      );
      final expiredClaim = await store.claimNext(workerId: 'worker-expired');
      expect(expiredClaim?.job.id, expiredRunning.job.id);
      expect(await store.markRunning(expiredClaim!), isTrue);
      await _expireLease(pool, expiredRunning.job.id);
      expect(await store.claimNext(workerId: 'worker-next'), isNull);
      expect(
        (await store.get(_ownerId, expiredRunning.job.id))?.status,
        BattleJobStatus.engineError,
      );
      expect(
        await store.transitionTerminal(
          expiredClaim,
          _terminal(expiredRunning.job, BattleJobStatus.cancelled),
        ),
        isFalse,
      );

      final completed = await service.create(
        userId: _ownerId,
        input: _input('completed-replay'),
      );
      final completedClaim = await store.claimNext(workerId: 'worker-complete');
      expect(completedClaim?.job.id, completed.job.id);
      expect(await store.markRunning(completedClaim!), isTrue);
      final persisted = await _persistAttemptAndReplay(pool, completed.job);
      await pool.execute(
        Sql.named('''
          UPDATE battle_simulation_attempts
          SET deck_a_hash = @wrong_hash
          WHERE id = CAST(@attempt_id AS uuid)
        '''),
        parameters: {'attempt_id': persisted.attemptId, 'wrong_hash': 'f' * 64},
      );
      expect(
        await store.transitionTerminal(
          completedClaim,
          BattleJobTerminalUpdate(
            status: BattleJobStatus.completed,
            requestHash: completed.job.requestHash,
            deckAHash: completed.job.deckAHash,
            deckBHash: completed.job.deckBHash,
            engine: 'manaloom_native_reviewed',
            engineProcessId: 'native-live-process',
            engineRequestSchemaVersion: nativeBattleDispatchSchema,
            engineRequestHash: 'e' * 64,
            engineRequestCorrelationSource: serverDispatchRecordedCorrelation,
            attemptId: persisted.attemptId,
            replayId: persisted.replayId,
          ),
        ),
        isFalse,
        reason: 'A replay attempt with a different frozen deck must be fenced.',
      );
      await pool.execute(
        Sql.named('''
          UPDATE battle_simulation_attempts
          SET deck_a_hash = @deck_a_hash
          WHERE id = CAST(@attempt_id AS uuid)
        '''),
        parameters: {
          'attempt_id': persisted.attemptId,
          'deck_a_hash': completed.job.deckAHash,
        },
      );
      expect(
        await store.transitionTerminal(
          completedClaim,
          BattleJobTerminalUpdate(
            status: BattleJobStatus.completed,
            requestHash: completed.job.requestHash,
            deckAHash: completed.job.deckAHash,
            deckBHash: completed.job.deckBHash,
            engine: 'manaloom_native_reviewed',
            engineProcessId: 'native-live-process',
            engineRequestSchemaVersion: nativeBattleDispatchSchema,
            engineRequestHash: 'e' * 64,
            engineRequestCorrelationSource: serverDispatchRecordedCorrelation,
            attemptId: persisted.attemptId,
            replayId: persisted.replayId,
          ),
        ),
        isTrue,
      );
      final completedRow = await store.get(_ownerId, completed.job.id);
      expect(completedRow?.status, BattleJobStatus.completed);
      expect(completedRow?.attemptId, persisted.attemptId);
      expect(completedRow?.replayId, persisted.replayId);
      expect(completedRow?.engineProcessId, 'native-live-process');
      expect(completedRow?.engineRequestHash, 'e' * 64);

      final concurrentService = BattleJobService(
        store,
        quotaPolicy: const BattleJobQuotaPolicy(
          perUserActiveLimit: 3,
          globalActiveLimit: 4,
        ),
      );
      final laneOne = await concurrentService.create(
        userId: _ownerId,
        input: _input('multiworker-lane-one'),
      );
      final laneTwo = await concurrentService.create(
        userId: _ownerId,
        input: _input('multiworker-lane-two'),
      );
      final claims = await Future.wait([
        store.claimNext(workerId: 'worker-concurrent-a'),
        store.claimNext(workerId: 'worker-concurrent-b'),
      ]);
      expect(
        claims.whereType<BattleJobClaim>(),
        hasLength(1),
        reason: 'Only one committed claim may reserve a native lane.',
      );
      final activeClaim = claims.whereType<BattleJobClaim>().single;
      expect({laneOne.job.id, laneTwo.job.id}, contains(activeClaim.job.id));
      expect(
        await store.transitionTerminal(
          activeClaim,
          _terminal(activeClaim.job, BattleJobStatus.cancelled),
        ),
        isTrue,
      );
      final nextClaim = await store.claimNext(workerId: 'worker-concurrent-c');
      expect(nextClaim, isNotNull);
      expect(
        await store.transitionTerminal(
          nextClaim!,
          _terminal(nextClaim.job, BattleJobStatus.cancelled),
        ),
        isTrue,
      );

      final autoLane = await concurrentService.create(
        userId: _ownerId,
        input: _input('multiworker-auto-lane', engine: 'auto'),
      );
      final explicitLane = await concurrentService.create(
        userId: _ownerId,
        input: _input('multiworker-explicit-lane'),
      );
      final autoClaims = await Future.wait([
        store.claimNext(workerId: 'worker-auto-a'),
        store.claimNext(workerId: 'worker-auto-b'),
      ]);
      expect(
        autoClaims.whereType<BattleJobClaim>(),
        hasLength(1),
        reason:
            'The auto lane must reserve every engine that it can reach by fallback.',
      );
      final autoClaim = autoClaims.whereType<BattleJobClaim>().single;
      expect(autoClaim.job.id, autoLane.job.id);
      expect(autoClaim.job.engineLane, 'auto');
      expect(
        await store.transitionTerminal(
          autoClaim,
          _terminal(autoClaim.job, BattleJobStatus.cancelled),
        ),
        isTrue,
      );
      final explicitClaim = await store.claimNext(
        workerId: 'worker-explicit-after-auto',
      );
      expect(explicitClaim?.job.id, explicitLane.job.id);
      expect(
        await store.transitionTerminal(
          explicitClaim!,
          _terminal(explicitClaim.job, BattleJobStatus.cancelled),
        ),
        isTrue,
      );

      final exhausted = await concurrentService.create(
        userId: _ownerId,
        input: _input('claimed-retry-exhausted'),
      );
      final exhaustedClaim = await store.claimNext(
        workerId: 'worker-exhausted',
      );
      expect(exhaustedClaim?.job.id, exhausted.job.id);
      await pool.execute(
        Sql.named('''
          UPDATE battle_jobs
          SET attempt_count = 100,
              lease_expires_at = CURRENT_TIMESTAMP - INTERVAL '1 second'
          WHERE id = CAST(@job_id AS uuid)
        '''),
        parameters: {'job_id': exhausted.job.id},
      );
      expect(
        await store.claimNext(workerId: 'worker-after-exhaustion'),
        isNull,
      );
      final exhaustedRow = await store.get(_ownerId, exhausted.job.id);
      expect(exhaustedRow?.status, BattleJobStatus.engineError);
      expect(exhaustedRow?.errorCode, 'battle_job_claim_retry_exhausted');

      final executable = await concurrentService.create(
        userId: _ownerId,
        input: _input('persistent-executor'),
      );
      final adapter = _NativeSuccessAdapter();
      final config = BattleEngineConfig.fromEnvironment(const {
        'BATTLE_ENGINE': 'native',
        'NATIVE_BATTLE_SIDECAR_URL': 'http://native.invalid',
      });
      final executor = PersistentBattleJobExecutor(
        pool,
        environment: const {},
        runtimeFactory:
            (_) => BattleExecutionRuntime(config: config, adapter: adapter),
      );
      final execution =
          await BattleJobRunner(
            store: store,
            executor: executor,
            workerId: 'worker-persistent-executor',
            leaseDuration: const Duration(minutes: 1),
            heartbeatInterval: const Duration(seconds: 10),
          ).runNext();
      expect(execution.state, BattleJobRunState.terminal);
      expect(execution.status, BattleJobStatus.completed);
      expect(adapter.calls, 1);

      final correlation = await pool.execute(
        Sql.named('''
          SELECT
            job.request_hash,
            job.engine_request_hash,
            attempt.job_request_hash,
            attempt.request_hash,
            attempt.engine_request_correlation_source,
            replay.game_log->'request_correlation'->>'job_request_hash',
            replay.game_log->'request_correlation'->>'engine_request_hash'
          FROM battle_jobs job
          JOIN battle_simulation_attempts attempt
            ON attempt.id = job.attempt_id
          JOIN battle_simulations replay
            ON replay.id = job.replay_id
          WHERE job.id = CAST(@job_id AS uuid)
        '''),
        parameters: {'job_id': executable.job.id},
      );
      final values = correlation.single;
      expect(values[0], executable.job.requestHash);
      expect(values[2], values[0]);
      expect(values[3], values[1]);
      expect(values[4], serverDispatchRecordedCorrelation);
      expect(values[5], values[0]);
      expect(values[6], values[1]);

      final failed = await concurrentService.create(
        userId: _ownerId,
        input: _input('persistent-engine-failure'),
      );
      final failedExecution =
          await BattleJobRunner(
            store: store,
            executor: PersistentBattleJobExecutor(
              pool,
              environment: const {},
              runtimeFactory:
                  (_) => BattleExecutionRuntime(
                    config: config,
                    adapter: _NativeFailureAdapter(),
                  ),
            ),
            workerId: 'worker-persistent-failure',
            leaseDuration: const Duration(minutes: 1),
            heartbeatInterval: const Duration(seconds: 10),
          ).runNext();
      expect(failedExecution.status, BattleJobStatus.engineError);
      final failedCorrelation = await pool.execute(
        Sql.named('''
          SELECT
            job.request_hash,
            job.engine_request_hash,
            job.engine_request_correlation_source,
            job.engine,
            attempt.job_request_hash,
            attempt.request_hash,
            attempt.engine_request_correlation_source,
            attempt.engine,
            attempt.outcome
          FROM battle_jobs job
          JOIN battle_simulation_attempts attempt
            ON attempt.id = job.attempt_id
          WHERE job.id = CAST(@job_id AS uuid)
        '''),
        parameters: {'job_id': failed.job.id},
      );
      final failedValues = failedCorrelation.single;
      expect(failedValues[1], isNotNull);
      expect(failedValues[2], serverDispatchRecordedCorrelation);
      expect(failedValues[3], 'manaloom_native_reviewed');
      expect(failedValues[4], failedValues[0]);
      expect(failedValues[5], failedValues[1]);
      expect(failedValues[6], failedValues[2]);
      expect(failedValues[7], failedValues[3]);
      expect(failedValues[8], 'engine_error');

      await pool.execute(
        Sql.named('''
          UPDATE decks
          SET deleted_at = CURRENT_TIMESTAMP
          WHERE id = CAST(@deck_b AS uuid)
        '''),
        parameters: {'deck_b': _deckBId},
      );
      await expectLater(
        concurrentService.create(
          userId: _ownerId,
          input: _input('soft-deleted-opponent'),
        ),
        throwsA(isA<BattleJobNotFoundException>()),
      );
    },
    skip: skipReason,
  );
}

class _NativeSuccessAdapter implements BattleEngineDispatchAdapter {
  int calls = 0;

  @override
  Future<Map<String, dynamic>> simulateNative({
    required BattleEngineConfig config,
    required Map<String, dynamic> request,
    required int timeoutMs,
  }) async {
    calls++;
    return {
      'status': 'completed',
      'engine': 'manaloom_native_reviewed',
      'engine_contract': 'native_reviewed_rules_execution',
      'turns': 3,
      'winner': 'Deck A',
      'sidecar_process_id': 'native-persistent-executor',
      'sidecar_started_at': '2026-07-26T12:00:00Z',
      'events': const <Map<String, dynamic>>[],
      'visual_snapshots': const <Map<String, dynamic>>[],
    };
  }

  @override
  Future<Map<String, dynamic>> simulateForge({
    required BattleEngineConfig config,
    required Map<String, dynamic> request,
    required int timeoutMs,
  }) async => throw StateError('Forge must not be dispatched.');

  @override
  Future<Map<String, dynamic>> simulateXmage({
    required BattleEngineConfig config,
    required Map<String, dynamic> request,
    required int timeoutMs,
  }) async => throw StateError('XMage must not be dispatched.');
}

class _NativeFailureAdapter implements BattleEngineDispatchAdapter {
  @override
  Future<Map<String, dynamic>> simulateNative({
    required BattleEngineConfig config,
    required Map<String, dynamic> request,
    required int timeoutMs,
  }) async {
    throw NativeBattleServiceException(
      'injected operational failure',
      statusCode: 502,
    );
  }

  @override
  Future<Map<String, dynamic>> simulateForge({
    required BattleEngineConfig config,
    required Map<String, dynamic> request,
    required int timeoutMs,
  }) async => throw StateError('Forge must not be dispatched.');

  @override
  Future<Map<String, dynamic>> simulateXmage({
    required BattleEngineConfig config,
    required Map<String, dynamic> request,
    required int timeoutMs,
  }) async => throw StateError('XMage must not be dispatched.');
}

BattleJobCreateInput _input(
  String key, {
  int maxTurns = 30,
  String engine = 'native',
}) {
  return BattleJobCreateInput.parse({
    'deck_id': _deckAId,
    'opponent_deck_id': _deckBId,
    'engine': engine,
    'max_turns': maxTurns,
    'idempotency_key': key,
  });
}

BattleJobTerminalUpdate _terminal(BattleJob job, BattleJobStatus status) {
  return BattleJobTerminalUpdate(
    status: status,
    requestHash: job.requestHash,
    deckAHash: job.deckAHash,
    deckBHash: job.deckBHash,
    terminalReason: status.value,
  );
}

Future<void> _seed(Pool pool) async {
  await pool.execute(
    Sql.named('''
      INSERT INTO users (id, username, email, password_hash)
      VALUES
        (CAST(@owner_id AS uuid), 'battle_live_owner',
         'battle_live_owner@example.com', 'unused'),
        (CAST(@other_id AS uuid), 'battle_live_other',
         'battle_live_other@example.com', 'unused')
    '''),
    parameters: {'owner_id': _ownerId, 'other_id': _otherId},
  );
  await pool.execute(
    Sql.named('''
      INSERT INTO cards (id, scryfall_id, name, set_code, collector_number)
      VALUES
        (CAST(@commander_id AS uuid), CAST(@commander_scryfall_id AS uuid),
         'Battle Live Commander', 'TST', '1'),
        (CAST(@main_id AS uuid), CAST(@main_scryfall_id AS uuid),
         'Battle Live Main', 'TST', '2')
    '''),
    parameters: {
      'commander_id': _commanderId,
      'commander_scryfall_id': _commanderScryfallId,
      'main_id': _mainCardId,
      'main_scryfall_id': _mainScryfallId,
    },
  );
  await pool.execute(
    Sql.named('''
      INSERT INTO decks (id, user_id, name, format, is_public)
      VALUES
        (CAST(@deck_a AS uuid), CAST(@owner_id AS uuid),
         'Battle Live A', 'commander', FALSE),
        (CAST(@deck_b AS uuid), CAST(@other_id AS uuid),
         'Battle Live B', 'commander', TRUE)
    '''),
    parameters: {
      'deck_a': _deckAId,
      'deck_b': _deckBId,
      'owner_id': _ownerId,
      'other_id': _otherId,
    },
  );
  await pool.execute(
    Sql.named('''
      INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander)
      VALUES
        (CAST(@deck_a AS uuid), CAST(@commander AS uuid), 1, TRUE),
        (CAST(@deck_a AS uuid), CAST(@main AS uuid), 99, FALSE),
        (CAST(@deck_b AS uuid), CAST(@commander AS uuid), 1, TRUE),
        (CAST(@deck_b AS uuid), CAST(@main AS uuid), 99, FALSE)
    '''),
    parameters: {
      'deck_a': _deckAId,
      'deck_b': _deckBId,
      'commander': _commanderId,
      'main': _mainCardId,
    },
  );
}

Future<void> _expireLease(Pool pool, String jobId) {
  return pool
      .execute(
        Sql.named('''
      UPDATE battle_jobs
      SET lease_expires_at = CURRENT_TIMESTAMP - INTERVAL '1 second'
      WHERE id = CAST(@id AS uuid)
    '''),
        parameters: {'id': jobId},
      )
      .then((_) {});
}

Future<({String attemptId, String replayId})> _persistAttemptAndReplay(
  Pool pool,
  BattleJob job,
) async {
  final replay = await pool.execute(
    Sql.named('''
      INSERT INTO battle_simulations (
        deck_a_id,
        deck_b_id,
        simulation_type,
        game_log,
        metrics
      )
      VALUES (
        CAST(@deck_a AS uuid),
        CAST(@deck_b AS uuid),
        'battle',
        '{}'::jsonb,
        '{}'::jsonb
      )
      RETURNING id::text
    '''),
    parameters: {'deck_a': _deckAId, 'deck_b': _deckBId},
  );
  final replayId = replay.single[0] as String;
  final attempt = await pool.execute(
    Sql.named('''
      INSERT INTO battle_simulation_attempts (
        user_id,
        deck_a_id,
        deck_b_id,
        replay_id,
        simulation_type,
        test_objective,
        outcome,
        request_id,
        request_schema_version,
        request_hash,
        job_request_schema_version,
        job_request_hash,
        deck_hash_schema,
        deck_a_hash,
        deck_b_hash,
        engine,
        engine_process_id,
        engine_request_correlation_source,
        timeout_ms,
        provenance,
        finished_at
      )
      VALUES (
        CAST(@user_id AS uuid),
        CAST(@deck_a AS uuid),
        CAST(@deck_b AS uuid),
        CAST(@replay_id AS uuid),
        'battle',
        'general',
        'completed',
        @request_id,
        @request_schema_version,
        @request_hash,
        @job_request_schema_version,
        @job_request_hash,
        @deck_hash_schema,
        @deck_a_hash,
        @deck_b_hash,
        'manaloom_native_reviewed',
        'native-live-process',
        @engine_request_correlation_source,
        @timeout_ms,
        '{}'::jsonb,
        CURRENT_TIMESTAMP
      )
      RETURNING id::text
    '''),
    parameters: {
      'user_id': _ownerId,
      'deck_a': _deckAId,
      'deck_b': _deckBId,
      'replay_id': replayId,
      'request_id': 'battle-job-${job.id}',
      'request_schema_version': nativeBattleDispatchSchema,
      'request_hash': 'e' * 64,
      'job_request_schema_version': job.requestSchemaVersion,
      'job_request_hash': job.requestHash,
      'engine_request_correlation_source': serverDispatchRecordedCorrelation,
      'deck_hash_schema': job.deckHashSchema,
      'deck_a_hash': job.deckAHash,
      'deck_b_hash': job.deckBHash,
      'timeout_ms': job.timeoutMs,
    },
  );
  return (attemptId: attempt.single[0] as String, replayId: replayId);
}
