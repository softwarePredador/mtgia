@Tags(['live', 'live_db_write'])
library;

import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:server/ai/battle_engine_config.dart';
import 'package:server/battle/battle_job_contract.dart';
import 'package:server/battle/interactive_battle_contract.dart';
import 'package:server/battle/interactive_battle_deck_lifecycle.dart';
import 'package:server/battle/interactive_battle_metrics_service.dart';
import 'package:server/battle/interactive_battle_runtime_client.dart';
import 'package:server/battle/interactive_battle_store.dart';
import 'package:server/health_readiness_support.dart';
import 'package:test/test.dart';

void main() {
  final enabled =
      Platform.environment['RUN_INTERACTIVE_BATTLE_DB_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer PostgreSQL descartável explicitamente isolado.';
  late Pool pool;
  late InteractiveBattleStore store;

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
    store = InteractiveBattleStore(pool);
    await _seed(pool);
  });

  tearDownAll(() async {
    if (enabled) await pool.close();
  });

  test(
    'PostgreSQL preserves owner scope, quota, stale checks, and append-only log',
    () async {
      expect((await evaluateReleaseSchemaReadiness(pool)).healthy, isTrue);
      expect(await probeInteractiveBattleSchema(pool), isTrue);

      final command = _command(
        id: _sessionId,
        idempotencyKey: 'interactive-live-create-1',
      );
      final created = await store.create(
        command,
        perUserActiveLimit: 1,
        globalActiveLimit: 4,
      );
      await pool.execute(
        Sql.named('''
          UPDATE interactive_battle_sessions
          SET attempt_id = NULL
          WHERE id = CAST(@session_id AS uuid)
        '''),
        parameters: {'session_id': _sessionId},
      );
      final duplicate = await store.create(
        command,
        perUserActiveLimit: 1,
        globalActiveLimit: 4,
      );
      expect(created.created, isTrue);
      expect(duplicate.created, isFalse);
      expect(created.session.attemptId, isNotNull);
      expect(duplicate.session.attemptId, created.session.attemptId);
      expect(duplicate.requestPayload, created.requestPayload);
      await pool.execute(
        Sql.named('''
          UPDATE decks
          SET name = 'Interactive B mutated after admission',
              is_public = FALSE
          WHERE id = CAST(@deck_id AS uuid)
        '''),
        parameters: {'deck_id': _deckBId},
      );
      final frozenRetry = await store.findCreate(
        userId: _ownerId,
        idempotencyKey: command.idempotencyKey,
        requestFingerprint: command.requestFingerprint,
      );
      expect(frozenRetry, isNotNull);
      expect(frozenRetry!.session.id, created.session.id);
      expect(frozenRetry.requestPayload, created.requestPayload);
      await pool.execute(
        Sql.named('''
          UPDATE decks
          SET is_public = TRUE
          WHERE id = CAST(@deck_id AS uuid)
        '''),
        parameters: {'deck_id': _deckBId},
      );
      final admissionAttempts = await pool.execute(
        Sql.named('''
          SELECT COUNT(*)::int
          FROM battle_simulation_attempts
          WHERE user_id = CAST(@user_id AS uuid)
            AND request_id = @request_id
        '''),
        parameters: {
          'user_id': _ownerId,
          'request_id': 'interactive-live-request-1',
        },
      );
      expect(admissionAttempts.single.single, 1);
      expect(await store.get(_ownerId, _sessionId), isNotNull);
      expect(await store.get(_otherId, _sessionId), isNull);

      await expectLater(
        store.create(
          _command(
            id: _secondSessionId,
            idempotencyKey: 'interactive-live-create-2',
          ),
          perUserActiveLimit: 1,
          globalActiveLimit: 4,
        ),
        throwsA(
          isA<InteractiveBattleQuotaExceededException>().having(
            (error) => error.scope,
            'scope',
            'user',
          ),
        ),
      );

      final waiting = await store.applyRuntimeSnapshot(
        userId: _ownerId,
        id: _sessionId,
        snapshot: _snapshot(),
      );
      expect(waiting.status, InteractiveBattleStatus.waitingForAction);
      expect(waiting.prompt?.id, _promptId);
      expect(waiting.privateState['own_hand'], hasLength(1));

      await pool.execute(
        Sql.named('''
          UPDATE interactive_battle_sessions
          SET prompt_deadline_at = CURRENT_TIMESTAMP - INTERVAL '1 second'
          WHERE id = CAST(@session_id AS uuid)
            AND user_id = CAST(@user_id AS uuid)
        '''),
        parameters: {'session_id': _sessionId, 'user_id': _ownerId},
      );
      final overdueMetrics =
          await InteractiveBattleMetricsService(pool).snapshot();
      final overdueActive = overdueMetrics['active'] as Map<String, dynamic>;
      expect(overdueActive['total'], 1);
      expect(overdueActive['waiting_for_action'], 1);
      expect(overdueActive['waiting_past_prompt_deadline'], 1);
      expect(overdueActive['ttl_expired_non_terminal'], 0);
      expect(overdueActive['max_age_seconds'], isA<int>());
      expect(overdueActive['max_prompt_overdue_seconds'], isA<int>());
      await expectLater(
        store.reserveAction(
          userId: _ownerId,
          id: _sessionId,
          action: InteractiveBattleActionInput(
            stateVersion: 4,
            promptId: _promptId,
            responseKind: InteractiveBattleResponseKind.delegate,
            idempotencyKey: 'interactive-action-after-deadline',
          ),
        ),
        throwsA(isA<InteractiveBattleStaleActionException>()),
      );
      final lateActionRecords = await pool.execute(
        Sql.named('''
          SELECT COUNT(*)::int
          FROM interactive_battle_records
          WHERE session_id = CAST(@session_id AS uuid)
            AND record_kind = 'action_submitted'
        '''),
        parameters: {'session_id': _sessionId},
      );
      expect(lateActionRecords.single.single, 0);
      await pool.execute(
        Sql.named('''
          UPDATE interactive_battle_sessions
          SET prompt_deadline_at = CURRENT_TIMESTAMP + INTERVAL '1 minute'
          WHERE id = CAST(@session_id AS uuid)
            AND user_id = CAST(@user_id AS uuid)
        '''),
        parameters: {'session_id': _sessionId, 'user_id': _ownerId},
      );

      final action = InteractiveBattleActionInput.parse({
        'state_version': 4,
        'prompt_id': _promptId,
        'delegate': true,
      }, headerIdempotencyKey: 'interactive-action-1');
      final reserved = await store.reserveAction(
        userId: _ownerId,
        id: _sessionId,
        action: action,
      );
      final repeated = await store.reserveAction(
        userId: _ownerId,
        id: _sessionId,
        action: action,
      );
      expect(reserved.duplicate, isFalse);
      expect(reserved.session.status, InteractiveBattleStatus.actionPending);
      expect(repeated.duplicate, isTrue);

      final acceptedSnapshot = _snapshot(
        acceptedActionReceipts: [
          InteractiveBattleAcceptedActionReceipt(
            actionId: action.idempotencyKey,
            requestFingerprint: action.requestFingerprint,
            kind: 'response',
            acceptedStateVersion: action.stateVersion,
          ),
        ],
      );
      final reconciled = await Future.wait([
        store.applyRuntimeSnapshot(
          userId: _ownerId,
          id: _sessionId,
          snapshot: acceptedSnapshot,
        ),
        store.applyRuntimeSnapshot(
          userId: _ownerId,
          id: _sessionId,
          snapshot: acceptedSnapshot,
        ),
      ]);
      expect(reconciled.map((session) => session.status).toSet(), {
        InteractiveBattleStatus.waitingForAction,
      });
      final durableRetry = await store.reserveAction(
        userId: _ownerId,
        id: _sessionId,
        action: action,
      );
      expect(durableRetry.duplicate, isTrue);
      expect(durableRetry.alreadyAccepted, isTrue);
      final acceptedAfterRead = await pool.execute(
        Sql.named('''
          SELECT COUNT(*)::int
          FROM interactive_battle_records
          WHERE session_id = CAST(@session_id AS uuid)
            AND record_kind = 'action_accepted'
            AND payload ->> 'action_id' = @action_id
        '''),
        parameters: {
          'session_id': _sessionId,
          'action_id': action.idempotencyKey,
        },
      );
      expect(acceptedAfterRead.single.single, 1);

      final forgedAction = InteractiveBattleActionInput.parse({
        'state_version': 4,
        'prompt_id': _promptId,
        'delegate': true,
      }, headerIdempotencyKey: 'interactive-action-forged-receipt');
      await store.reserveAction(
        userId: _ownerId,
        id: _sessionId,
        action: forgedAction,
      );
      await expectLater(
        store.applyRuntimeSnapshot(
          userId: _ownerId,
          id: _sessionId,
          snapshot: _snapshot(
            acceptedActionReceipts: [
              InteractiveBattleAcceptedActionReceipt(
                actionId: forgedAction.idempotencyKey,
                requestFingerprint: 'f' * 64,
                kind: 'response',
                acceptedStateVersion: forgedAction.stateVersion,
              ),
            ],
          ),
        ),
        throwsA(
          isA<InteractiveBattlePersistenceException>().having(
            (error) => error.code,
            'code',
            'interactive_battle_action_receipt_mismatch',
          ),
        ),
      );
      final forgedRollback = await pool.execute(
        Sql.named('''
          SELECT
            session.status,
            (
              SELECT COUNT(*)::int
              FROM interactive_battle_records record
              WHERE record.session_id = session.id
                AND record.record_kind = 'action_accepted'
                AND record.payload ->> 'action_id' = @action_id
            ) AS accepted_count
          FROM interactive_battle_sessions session
          WHERE session.id = CAST(@session_id AS uuid)
        '''),
        parameters: {
          'session_id': _sessionId,
          'action_id': forgedAction.idempotencyKey,
        },
      );
      expect(
        forgedRollback.single.toColumnMap()['status'],
        InteractiveBattleStatus.actionPending.value,
      );
      expect(forgedRollback.single.toColumnMap()['accepted_count'], 0);

      await expectLater(
        store.reserveAction(
          userId: _ownerId,
          id: _sessionId,
          action: InteractiveBattleActionInput(
            stateVersion: 4,
            promptId: _promptId,
            responseKind: InteractiveBattleResponseKind.delegate,
            idempotencyKey: 'interactive-action-1',
          ),
        ),
        completes,
      );
      await expectLater(
        store.reserveAction(
          userId: _ownerId,
          id: _sessionId,
          action: InteractiveBattleActionInput(
            stateVersion: 3,
            promptId: _promptId,
            responseKind: InteractiveBattleResponseKind.delegate,
            idempotencyKey: 'interactive-action-stale',
          ),
        ),
        throwsA(isA<InteractiveBattleStaleActionException>()),
      );

      final record = await pool.execute(
        Sql.named('''
          SELECT id::text
          FROM interactive_battle_records
          WHERE session_id = CAST(@session_id AS uuid)
          ORDER BY sequence
          LIMIT 1
        '''),
        parameters: {'session_id': _sessionId},
      );
      await expectLater(
        pool.execute(
          Sql.named('''
            UPDATE interactive_battle_records
            SET payload = '{"tampered":true}'::jsonb
            WHERE id = CAST(@record_id AS uuid)
          '''),
          parameters: {'record_id': record.single.single},
        ),
        throwsA(isA<ServerException>()),
      );

      await pool.execute('''
        CREATE OR REPLACE FUNCTION
          manaloom_test_fail_interactive_attempt_finish()
        RETURNS trigger
        LANGUAGE plpgsql
        AS \$failure_injection\$
        BEGIN
          RAISE EXCEPTION 'injected_interactive_attempt_finish_failure';
        END;
        \$failure_injection\$;
      ''');
      await pool.execute('''
        CREATE TRIGGER manaloom_test_fail_interactive_attempt_finish
        BEFORE UPDATE ON battle_simulation_attempts
        FOR EACH ROW
        EXECUTE FUNCTION manaloom_test_fail_interactive_attempt_finish();
      ''');
      final terminalSnapshot = _terminalSnapshot();
      final publicReplay = _publicReplay();
      await expectLater(
        store.finalizeRuntimeSnapshot(
          userId: _ownerId,
          id: _sessionId,
          snapshot: terminalSnapshot,
          replay: publicReplay,
          actionId: 'interactive-action-1',
        ),
        throwsA(isA<ServerException>()),
      );
      final rolledBack = await pool.execute(
        Sql.named('''
          SELECT
            session.status,
            session.replay_id::text,
            attempt.outcome,
            attempt.replay_id::text,
            (
              SELECT COUNT(*)::int
              FROM battle_simulations replay
              WHERE replay.game_log ->> 'request_id' = @request_id
            ) AS replay_count,
            (
              SELECT COUNT(*)::int
              FROM interactive_battle_records record
              WHERE record.session_id = session.id
                AND record.record_kind IN ('terminal', 'replay_linked')
            ) AS terminal_record_count
          FROM interactive_battle_sessions session
          JOIN battle_simulation_attempts attempt
            ON attempt.id = session.attempt_id
          WHERE session.id = CAST(@session_id AS uuid)
        '''),
        parameters: {
          'session_id': _sessionId,
          'request_id': 'interactive-live-request-1',
        },
      );
      final rolledBackRow = rolledBack.single.toColumnMap();
      expect(
        rolledBackRow['status'],
        InteractiveBattleStatus.actionPending.value,
      );
      expect(rolledBackRow['replay_id'], isNull);
      expect(rolledBackRow['outcome'], isNull);
      expect(rolledBackRow['replay_count'], 0);
      expect(rolledBackRow['terminal_record_count'], 0);
      await pool.execute('''
        DROP TRIGGER manaloom_test_fail_interactive_attempt_finish
          ON battle_simulation_attempts;
      ''');
      await pool.execute('''
        DROP FUNCTION manaloom_test_fail_interactive_attempt_finish();
      ''');

      final concurrent = await Future.wait([
        store.finalizeRuntimeSnapshot(
          userId: _ownerId,
          id: _sessionId,
          snapshot: terminalSnapshot,
          replay: publicReplay,
          actionId: 'interactive-action-1',
        ),
        store.finalizeRuntimeSnapshot(
          userId: _ownerId,
          id: _sessionId,
          snapshot: terminalSnapshot,
          replay: publicReplay,
          actionId: 'interactive-action-1',
        ),
      ]);
      expect(concurrent.map((session) => session.status).toSet(), {
        InteractiveBattleStatus.conceded,
      });
      expect(concurrent.first.replayId, isNotNull);
      expect(concurrent.last.replayId, concurrent.first.replayId);
      final converged = await pool.execute(
        Sql.named('''
          SELECT
            session.status,
            session.replay_id::text AS session_replay_id,
            attempt.outcome,
            attempt.replay_id::text AS attempt_replay_id,
            (
              SELECT COUNT(*)::int
              FROM battle_simulations replay
              WHERE replay.game_log ->> 'request_id' = @request_id
            ) AS replay_count,
            (
              SELECT COUNT(*)::int
              FROM interactive_battle_records record
              WHERE record.session_id = session.id
                AND record.record_kind = 'terminal'
            ) AS terminal_record_count,
            (
              SELECT COUNT(*)::int
              FROM interactive_battle_records record
              WHERE record.session_id = session.id
                AND record.record_kind = 'replay_linked'
            ) AS replay_record_count,
            (
              SELECT COUNT(*)::int
              FROM interactive_battle_records record
              WHERE record.session_id = session.id
                AND record.record_kind = 'action_accepted'
                AND record.payload ->> 'action_id' = 'interactive-action-1'
            ) AS accepted_record_count
          FROM interactive_battle_sessions session
          JOIN battle_simulation_attempts attempt
            ON attempt.id = session.attempt_id
          WHERE session.id = CAST(@session_id AS uuid)
        '''),
        parameters: {
          'session_id': _sessionId,
          'request_id': 'interactive-live-request-1',
        },
      );
      final convergedRow = converged.single.toColumnMap();
      expect(convergedRow['status'], InteractiveBattleStatus.conceded.value);
      expect(convergedRow['outcome'], 'cancelled');
      expect(
        convergedRow['attempt_replay_id'],
        convergedRow['session_replay_id'],
      );
      expect(convergedRow['replay_count'], 1);
      expect(convergedRow['terminal_record_count'], 1);
      expect(convergedRow['replay_record_count'], 1);
      expect(convergedRow['accepted_record_count'], 1);

      await pool.execute('''
        CREATE OR REPLACE FUNCTION
          manaloom_test_fail_interactive_session_insert()
        RETURNS trigger
        LANGUAGE plpgsql
        AS \$admission_failure_injection\$
        BEGIN
          RAISE EXCEPTION 'injected_interactive_session_insert_failure';
        END;
        \$admission_failure_injection\$;
      ''');
      await pool.execute('''
        CREATE TRIGGER manaloom_test_fail_interactive_session_insert
        BEFORE INSERT ON interactive_battle_sessions
        FOR EACH ROW
        EXECUTE FUNCTION manaloom_test_fail_interactive_session_insert();
      ''');
      await expectLater(
        store.create(
          _command(
            id: _failedAdmissionSessionId,
            idempotencyKey: 'interactive-live-admission-failure',
            requestId: 'interactive-live-request-admission-failure',
            requestHash: 'e' * 64,
          ),
          perUserActiveLimit: 1,
          globalActiveLimit: 4,
        ),
        throwsA(isA<ServerException>()),
      );
      final failedAdmission = await pool.execute(
        Sql.named('''
          SELECT
            (
              SELECT COUNT(*)::int
              FROM interactive_battle_sessions
              WHERE id = CAST(@session_id AS uuid)
            ) AS session_count,
            (
              SELECT COUNT(*)::int
              FROM battle_simulation_attempts
              WHERE request_id = @request_id
            ) AS attempt_count
        '''),
        parameters: {
          'session_id': _failedAdmissionSessionId,
          'request_id': 'interactive-live-request-admission-failure',
        },
      );
      final failedAdmissionRow = failedAdmission.single.toColumnMap();
      expect(failedAdmissionRow['session_count'], 0);
      expect(failedAdmissionRow['attempt_count'], 0);
      await pool.execute('''
        DROP TRIGGER manaloom_test_fail_interactive_session_insert
          ON interactive_battle_sessions;
      ''');
      await pool.execute('''
        DROP FUNCTION manaloom_test_fail_interactive_session_insert();
      ''');

      final second = await store.create(
        _command(
          id: _secondSessionId,
          idempotencyKey: 'interactive-live-create-2',
          requestId: 'interactive-live-request-2',
          requestHash: 'd' * 64,
        ),
        perUserActiveLimit: 1,
        globalActiveLimit: 4,
      );
      final terminal = await store.finalizeLocal(
        userId: _ownerId,
        id: second.session.id,
        status: InteractiveBattleStatus.abandoned,
        reason: 'local_contract_test',
      );
      expect(terminal.status, InteractiveBattleStatus.abandoned);
      expect(terminal.finishedAt, isNotNull);
      final terminalMetrics =
          await InteractiveBattleMetricsService(pool).snapshot();
      expect((terminalMetrics['active'] as Map)['total'], 0);
      expect((terminalMetrics['terminals_24h'] as Map)['total'], 2);
      expect((terminalMetrics['terminals_24h'] as Map)['abandoned'], 1);

      await pool.execute(
        Sql.named('DELETE FROM users WHERE id = CAST(@id AS uuid)'),
        parameters: {'id': _ownerId},
      );
      final remaining = await pool.execute(
        Sql.named('''
          SELECT COUNT(*)::int
          FROM interactive_battle_records
          WHERE session_id = CAST(@session_id AS uuid)
        '''),
        parameters: {'session_id': _sessionId},
      );
      expect(remaining.single.single, 0);
    },
    skip: skipReason,
  );

  test(
    'deck lifecycle serializes create/delete and finalize/delete without replay loss',
    () async {
      await _seedLifecycle(pool);
      addTearDown(() async {
        await pool.execute('''
          DROP TRIGGER IF EXISTS manaloom_test_delay_interactive_create
            ON interactive_battle_sessions;
          DROP FUNCTION IF EXISTS manaloom_test_delay_interactive_create();
          DROP TRIGGER IF EXISTS manaloom_test_delay_interactive_replay
            ON battle_simulations;
          DROP FUNCTION IF EXISTS manaloom_test_delay_interactive_replay();
        ''');
        await pool.execute(
          Sql.named(
            'DELETE FROM users WHERE id IN '
            '(CAST(@owner AS uuid), CAST(@other AS uuid))',
          ),
          parameters: {'owner': _lifecycleOwnerId, 'other': _lifecycleOtherId},
        );
      });

      expect(
        await deleteDeckAfterBattleGuard(
          pool,
          userId: _lifecycleOtherId,
          deckId: _lifecycleDeckAId,
        ),
        InteractiveBattleDeckDeleteResult.notFound,
      );
      expect(
        await deleteDeckAfterBattleGuard(
          pool,
          userId: _lifecycleOwnerId,
          deckId: _missingDeckId,
        ),
        InteractiveBattleDeckDeleteResult.notFound,
      );

      await pool.execute('''
        CREATE OR REPLACE FUNCTION manaloom_test_delay_interactive_create()
        RETURNS trigger
        LANGUAGE plpgsql
        AS \$create_delay\$
        BEGIN
          PERFORM pg_sleep(0.75);
          RETURN NEW;
        END;
        \$create_delay\$;
        CREATE TRIGGER manaloom_test_delay_interactive_create
        BEFORE INSERT ON interactive_battle_sessions
        FOR EACH ROW
        EXECUTE FUNCTION manaloom_test_delay_interactive_create();
      ''');
      final createFuture = store.create(
        _command(
          id: _lifecycleSessionId,
          userId: _lifecycleOwnerId,
          deckA: _lifecycleDeckA,
          deckB: _lifecycleDeckB,
          idempotencyKey: 'lifecycle-create-delete-race',
          requestId: 'interactive-lifecycle-request-1',
          requestHash: _lifecycleRequestHash,
        ),
        perUserActiveLimit: 1,
        globalActiveLimit: 4,
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      var deleteCompleted = false;
      final deleteDuringCreate = deleteDeckAfterBattleGuard(
        pool,
        userId: _lifecycleOwnerId,
        deckId: _lifecycleDeckAId,
      ).then((result) {
        deleteCompleted = true;
        return result;
      });
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(deleteCompleted, isFalse);
      final created = await createFuture.timeout(const Duration(seconds: 5));
      expect(created.created, isTrue);
      expect(
        await deleteDuringCreate.timeout(const Duration(seconds: 5)),
        InteractiveBattleDeckDeleteResult.activeBattle,
      );
      await pool.execute('''
        DROP TRIGGER manaloom_test_delay_interactive_create
          ON interactive_battle_sessions;
        DROP FUNCTION manaloom_test_delay_interactive_create();
      ''');

      expect(
        await deleteDeckAfterBattleGuard(
          pool,
          userId: _lifecycleOtherId,
          deckId: _lifecycleDeckBId,
        ),
        InteractiveBattleDeckDeleteResult.activeBattle,
      );

      await pool.execute('''
        CREATE OR REPLACE FUNCTION manaloom_test_delay_interactive_replay()
        RETURNS trigger
        LANGUAGE plpgsql
        AS \$replay_delay\$
        BEGIN
          PERFORM pg_sleep(0.75);
          RETURN NEW;
        END;
        \$replay_delay\$;
        CREATE TRIGGER manaloom_test_delay_interactive_replay
        BEFORE INSERT ON battle_simulations
        FOR EACH ROW
        EXECUTE FUNCTION manaloom_test_delay_interactive_replay();
      ''');
      final terminalSnapshot = _terminalSnapshot(
        runtimeSessionId: _lifecycleRuntimeId,
        requestId: 'interactive-lifecycle-request-1',
        requestHash: _lifecycleRequestHash,
      );
      final terminalReplay = _publicReplay(
        requestId: 'interactive-lifecycle-request-1',
        requestHash: _lifecycleRequestHash,
      );
      final finalizeFuture = store.finalizeRuntimeSnapshot(
        userId: _lifecycleOwnerId,
        id: _lifecycleSessionId,
        snapshot: terminalSnapshot,
        replay: terminalReplay,
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final deleteDuringFinalize = deleteDeckAfterBattleGuard(
        pool,
        userId: _lifecycleOwnerId,
        deckId: _lifecycleDeckAId,
      );
      final results = await Future.wait<Object>([
        finalizeFuture,
        deleteDuringFinalize,
      ]).timeout(const Duration(seconds: 5));
      expect(
        (results.first as InteractiveBattleSession).status,
        InteractiveBattleStatus.conceded,
      );
      expect(results.last, InteractiveBattleDeckDeleteResult.activeBattle);
      await pool.execute('''
        DROP TRIGGER manaloom_test_delay_interactive_replay
          ON battle_simulations;
        DROP FUNCTION manaloom_test_delay_interactive_replay();
      ''');

      final beforeDelete = await pool.execute(
        Sql.named('''
          SELECT
            session.replay_id::text,
            attempt.replay_id::text AS attempt_replay_id,
            (SELECT COUNT(*)::int FROM battle_simulations replay
             WHERE replay.id = session.replay_id) AS replay_count,
            (SELECT COUNT(*)::int FROM interactive_battle_records record
             WHERE record.session_id = session.id) AS record_count
          FROM interactive_battle_sessions session
          JOIN battle_simulation_attempts attempt
            ON attempt.id = session.attempt_id
          WHERE session.id = CAST(@session_id AS uuid)
        '''),
        parameters: {'session_id': _lifecycleSessionId},
      );
      final beforeDeleteRow = beforeDelete.single.toColumnMap();
      expect(beforeDeleteRow['replay_id'], isNotNull);
      expect(
        beforeDeleteRow['attempt_replay_id'],
        beforeDeleteRow['replay_id'],
      );
      expect(beforeDeleteRow['replay_count'], 1);
      expect((beforeDeleteRow['record_count'] as int), greaterThanOrEqualTo(3));

      expect(
        await deleteDeckAfterBattleGuard(
          pool,
          userId: _lifecycleOwnerId,
          deckId: _lifecycleDeckAId,
        ),
        InteractiveBattleDeckDeleteResult.deleted,
      );
      expect(
        await deleteDeckAfterBattleGuard(
          pool,
          userId: _lifecycleOtherId,
          deckId: _lifecycleDeckBId,
        ),
        InteractiveBattleDeckDeleteResult.deleted,
      );
      final preserved = await pool.execute(
        Sql.named('''
          SELECT
            session.deck_a_id::text,
            session.deck_b_id::text,
            session.replay_id::text,
            attempt.deck_a_id::text AS attempt_deck_a_id,
            attempt.deck_b_id::text AS attempt_deck_b_id,
            attempt.replay_id::text AS attempt_replay_id,
            (SELECT COUNT(*)::int FROM battle_simulations replay
             WHERE replay.id = session.replay_id) AS replay_count,
            (SELECT COUNT(*)::int FROM interactive_battle_records record
             WHERE record.session_id = session.id) AS record_count
          FROM interactive_battle_sessions session
          JOIN battle_simulation_attempts attempt
            ON attempt.id = session.attempt_id
          WHERE session.id = CAST(@session_id AS uuid)
        '''),
        parameters: {'session_id': _lifecycleSessionId},
      );
      final preservedRow = preserved.single.toColumnMap();
      expect(preservedRow['deck_a_id'], isNull);
      expect(preservedRow['deck_b_id'], isNull);
      expect(preservedRow['attempt_deck_a_id'], isNull);
      expect(preservedRow['attempt_deck_b_id'], isNull);
      expect(preservedRow['replay_id'], isNotNull);
      expect(preservedRow['attempt_replay_id'], preservedRow['replay_id']);
      expect(preservedRow['replay_count'], 1);
      expect(preservedRow['record_count'], beforeDeleteRow['record_count']);
    },
    skip: skipReason,
  );
}

InteractiveBattleCreateCommand _command({
  required String id,
  required String idempotencyKey,
  String requestId = 'interactive-live-request-1',
  String requestHash = _requestHash,
  String userId = _ownerId,
  BattleJobDeckSnapshot deckA = _liveDeckA,
  BattleJobDeckSnapshot deckB = _liveDeckB,
}) {
  const ttlSeconds = 600;
  const promptTimeoutSeconds = 60;
  final input = InteractiveBattleCreateInput(
    deckId: deckA.id,
    opponentDeckId: deckB.id,
    ttlSeconds: ttlSeconds,
    promptTimeoutSeconds: promptTimeoutSeconds,
    idempotencyKey: idempotencyKey,
  );
  return InteractiveBattleCreateCommand(
    id: id,
    userId: userId,
    deckA: deckA,
    deckB: deckB,
    requestHash: requestHash,
    requestPayload: {
      'schema_version': interactiveBattleRequestSchema,
      'request_id': requestId,
      'session_id': id,
      'expected_engine': 'xmage',
      'ttl_seconds': ttlSeconds,
      'prompt_timeout_seconds': promptTimeoutSeconds,
      'deck_a': deckA.payload,
      'deck_b': deckB.payload,
      'deck_hashes': {
        'schema_version': externalBattleDeckHashSchema,
        'algorithm': 'sha256',
        'deck_a': deckA.hash,
        'deck_b': deckB.hash,
      },
      'request_hash': requestHash,
    },
    requestId: requestId,
    idempotencyKey: idempotencyKey,
    requestFingerprint: interactiveBattleCreateFingerprint(input: input),
    ttlSeconds: ttlSeconds,
    timeoutMs: 600000,
  );
}

InteractiveBattleRuntimeSnapshot _snapshot({
  List<InteractiveBattleAcceptedActionReceipt>? acceptedActionReceipts,
}) => InteractiveBattleRuntimeSnapshot(
  runtimeSessionId: _runtimeId,
  requestId: 'interactive-live-request-1',
  requestHash: _requestHash,
  status: InteractiveBattleStatus.waitingForAction,
  stateVersion: 4,
  privateState: const {
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
  prompt: InteractiveBattlePrompt(
    id: _promptId,
    stateVersion: 4,
    kind: 'mulligan',
    inputMode: 'options',
    title: 'Mulligan',
    message: 'Manter esta mão?',
    deadlineAt: DateTime.now().toUtc().add(const Duration(minutes: 1)),
    options: const [
      InteractiveBattlePromptOption(
        id: _optionId,
        label: 'Manter esta mão',
        role: 'keep',
      ),
    ],
  ),
  engineVersion: '1.4.60',
  engineCommit: '34d81ea4995ce15d7e1a788dc6d2a3595d35bcec',
  engineBuild: 'xmage-sidecar-v2@34d81ea4995ce15d7e1a788dc6d2a3595d35bcec',
  engineProcessId: 'interactive-process-1',
  engineProcessStartedAt: DateTime.now().toUtc().subtract(
    const Duration(seconds: 10),
  ),
  lastActivityAt: DateTime.now().toUtc(),
  acceptedActionReceipts: acceptedActionReceipts,
);

InteractiveBattleRuntimeSnapshot _terminalSnapshot({
  String runtimeSessionId = _runtimeId,
  String requestId = 'interactive-live-request-1',
  String requestHash = _requestHash,
}) => InteractiveBattleRuntimeSnapshot(
  runtimeSessionId: runtimeSessionId,
  requestId: requestId,
  requestHash: requestHash,
  status: InteractiveBattleStatus.conceded,
  stateVersion: 5,
  privateState: const {
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
  engineVersion: '1.4.60',
  engineCommit: '34d81ea4995ce15d7e1a788dc6d2a3595d35bcec',
  engineBuild: 'xmage-sidecar-v2@34d81ea4995ce15d7e1a788dc6d2a3595d35bcec',
  engineProcessId: 'interactive-process-1',
  engineProcessStartedAt: DateTime.now().toUtc().subtract(
    const Duration(seconds: 10),
  ),
  lastActivityAt: DateTime.now().toUtc(),
  terminalReason: 'user_conceded',
  publicReplay: _publicReplay(requestId: requestId, requestHash: requestHash),
);

Map<String, dynamic> _publicReplay({
  String requestId = 'interactive-live-request-1',
  String requestHash = _requestHash,
}) => {
  'status': 'conceded',
  'winner': null,
  'turns': 1,
  'engine': 'xmage',
  'engine_contract': 'canonical_rules_execution',
  'engine_version': '1.4.60',
  'engine_commit': '34d81ea4995ce15d7e1a788dc6d2a3595d35bcec',
  'sidecar_build_identity':
      'xmage-sidecar-v2@34d81ea4995ce15d7e1a788dc6d2a3595d35bcec',
  'sidecar_process_id': 'interactive-process-1',
  'request_schema_version': interactiveBattleRequestSchema,
  'request_id': requestId,
  'request_hash': requestHash,
  'events': <Map<String, dynamic>>[],
  'visual_snapshots': <Map<String, dynamic>>[],
};

Future<void> _seed(Pool pool) async {
  await pool.execute(
    Sql.named('''
      INSERT INTO users (id, username, email, password_hash)
      VALUES
        (CAST(@owner_id AS uuid), 'interactive_056_owner',
         'interactive_056_owner@example.com', 'unused'),
        (CAST(@other_id AS uuid), 'interactive_056_other',
         'interactive_056_other@example.com', 'unused')
    '''),
    parameters: {'owner_id': _ownerId, 'other_id': _otherId},
  );
  await pool.execute(
    Sql.named('''
      INSERT INTO decks (
        id, user_id, name, format, is_public, validation_state,
        validation_reasons, validation_updated_at
      )
      VALUES
        (CAST(@deck_a AS uuid), CAST(@owner_id AS uuid),
         'Interactive A', 'commander', FALSE, 'validated', '[]'::jsonb,
         CURRENT_TIMESTAMP),
        (CAST(@deck_b AS uuid), CAST(@other_id AS uuid),
         'Interactive B', 'commander', TRUE, 'validated', '[]'::jsonb,
         CURRENT_TIMESTAMP)
    '''),
    parameters: {
      'deck_a': _deckAId,
      'deck_b': _deckBId,
      'owner_id': _ownerId,
      'other_id': _otherId,
    },
  );
}

Future<void> _seedLifecycle(Pool pool) async {
  await pool.execute(
    Sql.named('''
      INSERT INTO users (id, username, email, password_hash)
      VALUES
        (CAST(@owner_id AS uuid), 'interactive_lifecycle_owner',
         'interactive_lifecycle_owner@example.com', 'unused'),
        (CAST(@other_id AS uuid), 'interactive_lifecycle_other',
         'interactive_lifecycle_other@example.com', 'unused')
    '''),
    parameters: {'owner_id': _lifecycleOwnerId, 'other_id': _lifecycleOtherId},
  );
  await pool.execute(
    Sql.named('''
      INSERT INTO decks (
        id, user_id, name, format, is_public, validation_state,
        validation_reasons, validation_updated_at
      )
      VALUES
        (CAST(@deck_a AS uuid), CAST(@owner_id AS uuid),
         'Lifecycle A', 'commander', FALSE, 'validated', '[]'::jsonb,
         CURRENT_TIMESTAMP),
        (CAST(@deck_b AS uuid), CAST(@other_id AS uuid),
         'Lifecycle B', 'commander', TRUE, 'validated', '[]'::jsonb,
         CURRENT_TIMESTAMP)
    '''),
    parameters: {
      'deck_a': _lifecycleDeckAId,
      'deck_b': _lifecycleDeckBId,
      'owner_id': _lifecycleOwnerId,
      'other_id': _lifecycleOtherId,
    },
  );
}

const _liveDeckA = BattleJobDeckSnapshot(
  id: _deckAId,
  name: 'Interactive A',
  format: 'commander',
  validationState: 'validated',
  validationReasons: [],
  cards: [],
  hash: _deckAHash,
);
const _liveDeckB = BattleJobDeckSnapshot(
  id: _deckBId,
  name: 'Interactive B',
  format: 'commander',
  validationState: 'validated',
  validationReasons: [],
  cards: [],
  hash: _deckBHash,
);
const _lifecycleDeckA = BattleJobDeckSnapshot(
  id: _lifecycleDeckAId,
  name: 'Lifecycle A',
  format: 'commander',
  validationState: 'validated',
  validationReasons: [],
  cards: [],
  hash: _lifecycleDeckAHash,
);
const _lifecycleDeckB = BattleJobDeckSnapshot(
  id: _lifecycleDeckBId,
  name: 'Lifecycle B',
  format: 'commander',
  validationState: 'validated',
  validationReasons: [],
  cards: [],
  hash: _lifecycleDeckBHash,
);

const _ownerId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa6';
const _otherId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb6';
const _deckAId = '11111111-1111-4111-8111-111111111116';
const _deckBId = '22222222-2222-4222-8222-222222222226';
const _sessionId = '33333333-3333-4333-8333-333333333336';
const _secondSessionId = '44444444-4444-4444-8444-444444444446';
const _failedAdmissionSessionId = '55555555-5555-4555-8555-555555555556';
const _runtimeId = 'ibsrt_abcdefghijklmnop';
const _promptId = 'p_abcdefghijklmnop';
const _optionId = 'o_abcdefghijklmnop';
const _deckAHash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _deckBHash =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _requestHash =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _lifecycleOwnerId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa7';
const _lifecycleOtherId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb7';
const _lifecycleDeckAId = '11111111-1111-4111-8111-111111111117';
const _lifecycleDeckBId = '22222222-2222-4222-8222-222222222227';
const _lifecycleSessionId = '33333333-3333-4333-8333-333333333337';
const _missingDeckId = '99999999-9999-4999-8999-999999999999';
const _lifecycleRuntimeId = 'ibsrt_lifecycleabcdefg';
const _lifecycleDeckAHash =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
const _lifecycleDeckBHash =
    'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
const _lifecycleRequestHash =
    'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
