@Tags(['live', 'live_db_write'])
library;

import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:server/battle/battle_job_contract.dart';
import 'package:server/battle/interactive_battle_contract.dart';
import 'package:server/battle/interactive_battle_runtime_client.dart';
import 'package:server/battle/interactive_battle_service.dart';
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
        fingerprint: '4' * 64,
      );
      final created = await store.create(
        command,
        perUserActiveLimit: 1,
        globalActiveLimit: 4,
      );
      final duplicate = await store.create(
        command,
        perUserActiveLimit: 1,
        globalActiveLimit: 4,
      );
      expect(created.created, isTrue);
      expect(duplicate.created, isFalse);
      expect(await store.get(_ownerId, _sessionId), isNotNull);
      expect(await store.get(_otherId, _sessionId), isNull);

      await expectLater(
        store.create(
          _command(
            id: _secondSessionId,
            idempotencyKey: 'interactive-live-create-2',
            fingerprint: '5' * 64,
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

      final attemptId = await PostgresInteractiveBattlePersistence(
        pool,
      ).startAttempt(
        userId: _ownerId,
        deckAId: _deckAId,
        deckBId: _deckBId,
        requestId: 'interactive-live-request-1',
        requestHash: _requestHash,
        deckAHash: _deckAHash,
        deckBHash: _deckBHash,
        timeoutMs: 600000,
      );
      await store.attachAttempt(
        userId: _ownerId,
        id: _sessionId,
        attemptId: attemptId,
      );
      final waiting = await store.applyRuntimeSnapshot(
        userId: _ownerId,
        id: _sessionId,
        snapshot: _snapshot(),
        attemptId: attemptId,
      );
      expect(waiting.status, InteractiveBattleStatus.waitingForAction);
      expect(waiting.prompt?.id, _promptId);
      expect(waiting.privateState['own_hand'], hasLength(1));

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

      final terminal = await store.terminalize(
        userId: _ownerId,
        id: _sessionId,
        status: InteractiveBattleStatus.abandoned,
        reason: 'local_contract_test',
      );
      expect(terminal.status, InteractiveBattleStatus.abandoned);
      expect(terminal.finishedAt, isNotNull);

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
}

InteractiveBattleCreateCommand _command({
  required String id,
  required String idempotencyKey,
  required String fingerprint,
}) => InteractiveBattleCreateCommand(
  id: id,
  userId: _ownerId,
  deckA: const BattleJobDeckSnapshot(
    id: _deckAId,
    name: 'Interactive A',
    cards: [],
    hash: _deckAHash,
  ),
  deckB: const BattleJobDeckSnapshot(
    id: _deckBId,
    name: 'Interactive B',
    cards: [],
    hash: _deckBHash,
  ),
  requestHash: _requestHash,
  requestPayload: const {
    'schema_version': interactiveBattleRequestSchema,
    'request_id': 'interactive-live-request-1',
    'request_hash': _requestHash,
  },
  idempotencyKey: idempotencyKey,
  requestFingerprint: fingerprint,
  ttlSeconds: 600,
);

InteractiveBattleRuntimeSnapshot _snapshot() =>
    InteractiveBattleRuntimeSnapshot(
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
    );

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
      INSERT INTO decks (id, user_id, name, format, is_public)
      VALUES
        (CAST(@deck_a AS uuid), CAST(@owner_id AS uuid),
         'Interactive A', 'commander', FALSE),
        (CAST(@deck_b AS uuid), CAST(@other_id AS uuid),
         'Interactive B', 'commander', TRUE)
    '''),
    parameters: {
      'deck_a': _deckAId,
      'deck_b': _deckBId,
      'owner_id': _ownerId,
      'other_id': _otherId,
    },
  );
}

const _ownerId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa6';
const _otherId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb6';
const _deckAId = '11111111-1111-4111-8111-111111111116';
const _deckBId = '22222222-2222-4222-8222-222222222226';
const _sessionId = '33333333-3333-4333-8333-333333333336';
const _secondSessionId = '44444444-4444-4444-8444-444444444446';
const _runtimeId = 'ibsrt_abcdefghijklmnop';
const _promptId = 'p_abcdefghijklmnop';
const _optionId = 'o_abcdefghijklmnop';
const _deckAHash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _deckBHash =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _requestHash =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
