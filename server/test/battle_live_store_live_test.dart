@Tags(['live', 'live_db_write'])
library;

import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:server/battle/battle_job_metrics_service.dart';
import 'package:server/battle/battle_live_cursor_contract.dart';
import 'package:server/battle/battle_live_store.dart';
import 'package:server/health_readiness_support.dart';
import 'package:test/test.dart';

void main() {
  final enabled = Platform.environment['RUN_BATTLE_LIVE_DB_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer PostgreSQL descartavel explicitamente isolado.';
  late Pool pool;
  late BattleLiveStore store;

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
    store = BattleLiveStore(pool);
    await _seed(pool);
  });

  tearDownAll(() async {
    if (enabled) await pool.close();
  });

  test(
    'PostgreSQL preserves owner scope, checkpoints, dedupe, and cascade',
    () async {
      expect((await evaluateReleaseSchemaReadiness(pool)).healthy, isTrue);
      expect(await probeBattleLiveSchema(pool), isTrue);

      expect(await store.getJob(userId: _ownerId, jobId: _jobId), isNotNull);
      expect(await store.getJob(userId: _otherId, jobId: _jobId), isNull);

      final writes = [
        BattleLiveRecordWrite(
          kind: BattleLiveRecordKind.event,
          payload: const {'event_type': 'stack_entry', 'card_name': 'Sol Ring'},
          contentTruncated: false,
          fingerprint: 'a' * 64,
          sourceKind: 'xmage_live',
          sourceProcessId: 'process-1',
          sourceSequence: 0,
          sourceRecordId: 'battle-job:e:0',
        ),
        BattleLiveRecordWrite(
          kind: BattleLiveRecordKind.snapshot,
          payload: const {
            'turn': 1,
            'players': [
              {'deck_key': 'deck_a', 'life': 40, 'hand_size': 7},
            ],
          },
          contentTruncated: false,
          fingerprint: 'b' * 64,
          sourceKind: 'xmage_live',
          sourceProcessId: 'process-1',
          sourceSequence: 1,
          sourceRecordId: 'battle-job:s:1',
        ),
        BattleLiveRecordWrite(
          kind: BattleLiveRecordKind.event,
          payload: const {},
          contentTruncated: false,
          fingerprint: 'c' * 64,
          sourceKind: 'xmage_checkpoint',
          publicVisible: false,
          sourceProcessId: 'process-1',
          sourceSequence: 1,
        ),
      ];
      final inserted = await store.append(
        userId: _ownerId,
        jobId: _jobId,
        records: writes,
        sourceTruncated: true,
      );
      final repeated = await store.append(
        userId: _ownerId,
        jobId: _jobId,
        records: writes,
        sourceTruncated: true,
      );

      expect(inserted.appended, 2);
      expect(repeated.appended, 0);
      final records = await store.list(userId: _ownerId, jobId: _jobId);
      expect(records.records, hasLength(2));
      expect(records.records.map((record) => record.sequence), [0, 1]);
      expect(records.sourceTruncated, isTrue);
      expect(
        (await store.list(userId: _otherId, jobId: _jobId)).records,
        isEmpty,
      );
      final checkpoint = await store.sourceCheckpoint(
        userId: _ownerId,
        jobId: _jobId,
      );
      expect(checkpoint?.sourceProcessId, 'process-1');
      expect(checkpoint?.afterSequence, 1);

      final restartedStore = BattleLiveStore(pool);
      expect(
        (await restartedStore.list(userId: _ownerId, jobId: _jobId)).records,
        hasLength(2),
      );

      await expectLater(
        pool.execute(
          Sql.named('''
            INSERT INTO battle_job_live_records (
              job_id,
              sequence,
              record_id,
              kind,
              payload,
              fingerprint,
              source_kind,
              public_visible
            )
            VALUES (
              CAST(@job_id AS uuid),
              999,
              @record_id,
              'event',
              '{}'::jsonb,
              @fingerprint,
              'terminal_replay',
              FALSE
            )
          '''),
          parameters: {
            'job_id': _jobId,
            'record_id': 'blr-${'d' * 40}',
            'fingerprint': 'd' * 64,
          },
        ),
        throwsA(isA<ServerException>()),
      );

      await pool.execute(
        Sql.named('DELETE FROM battle_jobs WHERE id = CAST(@job_id AS uuid)'),
        parameters: {'job_id': _jobId},
      );
      final remaining = await pool.execute(
        Sql.named('''
          SELECT COUNT(*)::int
          FROM battle_job_live_records
          WHERE job_id = CAST(@job_id AS uuid)
        '''),
        parameters: {'job_id': _jobId},
      );
      expect(remaining.single.single, 0);

      final metrics = await BattleJobMetricsService(pool).snapshot();
      expect(metrics['schema_version'], battleJobMetricsSchemaVersion);
      expect(metrics['status'], 'ok');
      expect(
        (metrics['queue'] as Map<String, dynamic>)['depth'],
        greaterThanOrEqualTo(0),
      );
      expect(metrics.toString(), isNot(contains(_ownerId)));
      expect(metrics.toString(), isNot(contains(_jobId)));
    },
    skip: skipReason,
  );
}

Future<void> _seed(Pool pool) async {
  await pool.execute(
    Sql.named('''
      INSERT INTO users (id, username, email, password_hash)
      VALUES
        (CAST(@owner_id AS uuid), 'battle_live_055_owner',
         'battle_live_055_owner@example.com', 'unused'),
        (CAST(@other_id AS uuid), 'battle_live_055_other',
         'battle_live_055_other@example.com', 'unused')
    '''),
    parameters: {'owner_id': _ownerId, 'other_id': _otherId},
  );
  await pool.execute(
    Sql.named('''
      INSERT INTO battle_jobs (
        id,
        user_id,
        deck_hash_schema,
        deck_a_hash,
        deck_b_hash,
        request_schema_version,
        request_hash,
        request_payload,
        requested_engine,
        engine_lane,
        status,
        stage,
        timeout_ms,
        idempotency_key,
        request_fingerprint,
        quota_user_limit,
        quota_global_limit
      )
      VALUES (
        CAST(@job_id AS uuid),
        CAST(@owner_id AS uuid),
        'external_battle_deck_hash_v1',
        @deck_a_hash,
        @deck_b_hash,
        'battle_job_request_v1',
        @request_hash,
        CAST(@request_payload AS jsonb),
        'xmage',
        'xmage',
        'queued',
        'queued',
        40000,
        'battle-live-055',
        @request_fingerprint,
        3,
        24
      )
    '''),
    parameters: {
      'job_id': _jobId,
      'owner_id': _ownerId,
      'deck_a_hash': '1' * 64,
      'deck_b_hash': '2' * 64,
      'request_hash': '3' * 64,
      'request_payload': '{"request_id":"battle-job-$_jobId"}',
      'request_fingerprint': '4' * 64,
    },
  );
}

const _ownerId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _otherId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';
const _jobId = '11111111-1111-4111-8111-111111111115';
