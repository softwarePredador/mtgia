@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:server/ai/battle_engine_config.dart';
import 'package:server/battle/battle_execution_runtime.dart';
import 'package:server/battle/battle_job_contract.dart';
import 'package:test/test.dart';

import '../routes/ai/battle/jobs/[id]/index.dart' as job_route;
import '../routes/ai/battle/jobs/index.dart' as jobs_route;

const _ownerCount = 8;
const _jobsPerOwner = 3;
const _sampleCount = 7;
const _createP95BudgetMs = 5000;
const _listP95BudgetMs = 1000;
const _postgresP95BudgetMs = 500;
const _batchP95BudgetMs = 500;
const _cancelP95BudgetMs = 1000;
const _aggregateBudgetMs = 15000;
const _rssDeltaBudgetBytes = 128 * 1024 * 1024;
const _fixtureEmailPrefix = 'battle_load_20260729_';

final _ownerIds = List<String>.generate(
  _ownerCount,
  (index) => _uuid(10 + index),
  growable: false,
);
final _ownerDeckIds = List<String>.generate(
  _ownerCount,
  (index) => _uuid(110 + index),
  growable: false,
);
final _opponentUserId = _uuid(30);
final _opponentDeckId = _uuid(130);
final _commanderCardId = _uuid(210);
final _mainCardId = _uuid(211);
final _commanderScryfallId = _uuid(310);
final _mainScryfallId = _uuid(311);

void main() {
  final enabled = Platform.environment['RUN_BATTLE_JOB_LOAD_DB_TESTS'] == '1';
  final skipReason =
      enabled
          ? null
          : 'Requer o PostgreSQL loopback descartavel do gate de schema.';
  late Pool pool;

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
    await _cleanup(pool);
    await _seed(pool);
  });

  tearDownAll(() async {
    if (!enabled) return;
    await _cleanup(pool);
    await pool.close();
  });

  test(
    'BL10-03 route, PostgreSQL and batch lane stay bounded under 24 jobs',
    () async {
      final runtime = BattleExecutionRuntime(
        config: BattleEngineConfig.fromEnvironment(const {
          'BATTLE_ENGINE': 'native',
          'NATIVE_BATTLE_SIDECAR_URL': 'http://native.invalid',
        }),
        adapter: const _LoadNativeAdapter(),
      );
      final initialRss = ProcessInfo.currentRss;
      final baselineListMs = <int>[];
      final baselinePostgresMs = <int>[];
      final baselineBatchMs = <int>[];

      for (var sample = 0; sample < _sampleCount; sample++) {
        await _timed(baselineListMs, () async {
          final response = await jobs_route.onRequest(
            _context(
              method: HttpMethod.get,
              path: '/ai/battle/jobs?limit=100',
              pool: pool,
              userId: _ownerIds[sample % _ownerCount],
            ),
          );
          expect(response.statusCode, HttpStatus.ok);
          await response.body();
        });
        await _timed(baselinePostgresMs, () async {
          final result = await pool.execute(
            "SELECT COUNT(*)::int FROM battle_jobs WHERE status = 'queued'",
          );
          expect(result.single[0], 0);
        });
        await _timed(baselineBatchMs, () async {
          final result = await runtime.execute(
            request: _batchRequest(sample),
            requestedEngine: 'native',
          );
          expect(result.result['status'], 'completed');
        });
      }

      final createMs = <int>[];
      final loadedListMs = <int>[];
      final loadedPostgresMs = <int>[];
      final loadedBatchMs = <int>[];
      final createdJobs = <({String id, String ownerId})>[];
      final aggregate = Stopwatch()..start();

      final futures = <Future<void>>[];
      for (var owner = 0; owner < _ownerCount; owner++) {
        for (var job = 0; job < _jobsPerOwner; job++) {
          futures.add(
            _timed(createMs, () async {
              final response = await jobs_route.onRequest(
                _context(
                  method: HttpMethod.post,
                  path: '/ai/battle/jobs',
                  pool: pool,
                  userId: _ownerIds[owner],
                  body: {
                    'deck_id': _ownerDeckIds[owner],
                    'opponent_deck_id': _opponentDeckId,
                    'engine': 'native',
                    'max_turns': 30,
                    'idempotency_key': 'load-owner-$owner-job-$job',
                  },
                ),
              );
              final payload =
                  jsonDecode(await response.body()) as Map<String, dynamic>;
              expect(
                response.statusCode,
                HttpStatus.created,
                reason: jsonEncode(payload),
              );
              final created = (payload['job'] as Map).cast<String, dynamic>();
              createdJobs.add((
                id: created['job_id']! as String,
                ownerId: _ownerIds[owner],
              ));
            }),
          );
        }
      }
      for (var sample = 0; sample < 16; sample++) {
        futures.add(
          _timed(loadedListMs, () async {
            final response = await jobs_route.onRequest(
              _context(
                method: HttpMethod.get,
                path: '/ai/battle/jobs?limit=100',
                pool: pool,
                userId: _ownerIds[sample % _ownerCount],
              ),
            );
            expect(response.statusCode, HttpStatus.ok);
            await response.body();
          }),
        );
        futures.add(
          _timed(loadedPostgresMs, () async {
            final result = await pool.execute(
              "SELECT COUNT(*)::int FROM battle_jobs "
              "WHERE status IN ('queued', 'claimed', 'running', "
              "'cancel_pending')",
            );
            expect(result.single[0], isA<int>());
          }),
        );
        futures.add(
          _timed(loadedBatchMs, () async {
            final result = await runtime.execute(
              request: _batchRequest(100 + sample),
              requestedEngine: 'native',
            );
            expect(result.result['status'], 'completed');
          }),
        );
      }
      await Future.wait(futures);
      aggregate.stop();

      expect(createdJobs, hasLength(_ownerCount * _jobsPerOwner));
      for (var owner = 0; owner < _ownerCount; owner++) {
        final response = await jobs_route.onRequest(
          _context(
            method: HttpMethod.get,
            path: '/ai/battle/jobs?limit=100',
            pool: pool,
            userId: _ownerIds[owner],
          ),
        );
        final payload =
            jsonDecode(await response.body()) as Map<String, dynamic>;
        expect(response.statusCode, HttpStatus.ok);
        expect(payload['schema_version'], battleJobListSchemaVersion);
        expect(payload['jobs'], hasLength(_jobsPerOwner));
      }

      final cancelMs = <int>[];
      await Future.wait([
        for (final created in createdJobs)
          _timed(cancelMs, () async {
            final response = await job_route.onRequest(
              _context(
                method: HttpMethod.delete,
                path: '/ai/battle/jobs/${created.id}',
                pool: pool,
                userId: created.ownerId,
              ),
              created.id,
            );
            final payload =
                jsonDecode(await response.body()) as Map<String, dynamic>;
            expect(
              response.statusCode,
              HttpStatus.ok,
              reason: jsonEncode(payload),
            );
            expect((payload['job'] as Map)['status'], 'cancelled');
          }),
      ]);
      final active = await pool.execute(
        "SELECT COUNT(*)::int FROM battle_jobs "
        "WHERE status IN ('queued', 'claimed', 'running', 'cancel_pending')",
      );
      expect(active.single[0], 0);

      final rawRssDelta = ProcessInfo.currentRss - initialRss;
      final rssDelta = max(0, rawRssDelta);
      final measurements = <String, dynamic>{
        'baseline': {
          'route_list_p50_ms': _percentile(baselineListMs, 0.50),
          'route_list_p95_ms': _percentile(baselineListMs, 0.95),
          'postgres_p50_ms': _percentile(baselinePostgresMs, 0.50),
          'postgres_p95_ms': _percentile(baselinePostgresMs, 0.95),
          'batch_p50_ms': _percentile(baselineBatchMs, 0.50),
          'batch_p95_ms': _percentile(baselineBatchMs, 0.95),
        },
        'loaded': {
          'create_p50_ms': _percentile(createMs, 0.50),
          'create_p95_ms': _percentile(createMs, 0.95),
          'route_list_p50_ms': _percentile(loadedListMs, 0.50),
          'route_list_p95_ms': _percentile(loadedListMs, 0.95),
          'postgres_p50_ms': _percentile(loadedPostgresMs, 0.50),
          'postgres_p95_ms': _percentile(loadedPostgresMs, 0.95),
          'batch_p50_ms': _percentile(loadedBatchMs, 0.50),
          'batch_p95_ms': _percentile(loadedBatchMs, 0.95),
          'cancel_p50_ms': _percentile(cancelMs, 0.50),
          'cancel_p95_ms': _percentile(cancelMs, 0.95),
          'aggregate_ms': aggregate.elapsedMilliseconds,
          'rss_delta_bytes': rssDelta,
        },
      };

      expect(
        _percentile(createMs, 0.95),
        lessThanOrEqualTo(_createP95BudgetMs),
      );
      expect(
        _percentile(loadedListMs, 0.95),
        lessThanOrEqualTo(_listP95BudgetMs),
      );
      expect(
        _percentile(loadedPostgresMs, 0.95),
        lessThanOrEqualTo(_postgresP95BudgetMs),
      );
      expect(
        _percentile(loadedBatchMs, 0.95),
        lessThanOrEqualTo(_batchP95BudgetMs),
      );
      expect(
        _percentile(cancelMs, 0.95),
        lessThanOrEqualTo(_cancelP95BudgetMs),
      );
      expect(
        aggregate.elapsedMilliseconds,
        lessThanOrEqualTo(_aggregateBudgetMs),
      );
      expect(rssDelta, lessThanOrEqualTo(_rssDeltaBudgetBytes));

      // ignore: avoid_print
      print(
        'BATTLE_JOB_INTEGRATED_LOCAL_LOAD '
        '${jsonEncode({
          'schema': 'battle_job_integrated_local_load_v1',
          'classification': 'disposable_postgres_route_service_batch_preflight_not_target_load_proof',
          'fixture': {'owners': _ownerCount, 'jobs_per_owner': _jobsPerOwner, 'concurrent_jobs': _ownerCount * _jobsPerOwner, 'loaded_probe_samples': 16},
          'budgets': {'create_p95_ms': _createP95BudgetMs, 'route_list_p95_ms': _listP95BudgetMs, 'postgres_p95_ms': _postgresP95BudgetMs, 'batch_p95_ms': _batchP95BudgetMs, 'cancel_p95_ms': _cancelP95BudgetMs, 'aggregate_ms': _aggregateBudgetMs, 'rss_delta_bytes': _rssDeltaBudgetBytes},
          'measurements': measurements,
          'cleanup': {'active_jobs_after_cancel': active.single[0], 'disposable_database_owned_by_schema_gate': true},
          'blocked_proofs': const ['real_http_socket_and_middleware', 'target_cpu_profile', 'target_rss_profile', 'published_sidecars', 'same_sha_deployment'],
        })}',
      );
    },
    skip: skipReason,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<void> _timed(List<int> samples, Future<void> Function() action) async {
  final stopwatch = Stopwatch()..start();
  await action();
  stopwatch.stop();
  samples.add(stopwatch.elapsedMilliseconds);
}

int _percentile(List<int> values, double percentile) {
  final sorted = List<int>.of(values)..sort();
  final index = ((sorted.length - 1) * percentile).ceil();
  return sorted[index];
}

_LoadRequestContext _context({
  required HttpMethod method,
  required String path,
  required Pool pool,
  required String userId,
  Object? body,
}) => _LoadRequestContext(
  Request(
    method.name.toUpperCase(),
    Uri.parse('http://localhost$path'),
    headers:
        body == null ? const {} : const {'content-type': 'application/json'},
    body: body == null ? null : jsonEncode(body),
  ),
  pool,
  userId,
);

class _LoadRequestContext implements RequestContext {
  const _LoadRequestContext(this.request, this.pool, this.userId);

  @override
  final Request request;
  final Pool pool;
  final String userId;

  @override
  Map<String, String> get mountedParams => const {};

  @override
  RequestContext provide<T extends Object?>(T Function() create) => this;

  @override
  T read<T>() {
    if (T == Pool) return pool as T;
    if (T == String) return userId as T;
    throw StateError('No integrated load provider for $T');
  }
}

class _LoadNativeAdapter implements BattleEngineDispatchAdapter {
  const _LoadNativeAdapter();

  @override
  Future<Map<String, dynamic>> simulateNative({
    required BattleEngineConfig config,
    required Map<String, dynamic> request,
    required int timeoutMs,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 2));
    return {
      'status': 'completed',
      'engine': 'manaloom_native_reviewed',
      'engine_contract': 'native_reviewed_rules_execution',
      'turns': 3,
      'winner': 'Deck A',
      'sidecar_process_id': 'native-load-fixture',
      'sidecar_started_at': '2026-07-29T00:00:00Z',
      'events': const <Map<String, dynamic>>[],
      'visual_snapshots': const <Map<String, dynamic>>[],
    };
  }

  @override
  Future<Map<String, dynamic>> simulateForge({
    required BattleEngineConfig config,
    required Map<String, dynamic> request,
    required int timeoutMs,
  }) async => throw StateError('Forge is outside this local load fixture.');

  @override
  Future<Map<String, dynamic>> simulateXmage({
    required BattleEngineConfig config,
    required Map<String, dynamic> request,
    required int timeoutMs,
  }) async => throw StateError('XMage is outside this local load fixture.');
}

Map<String, dynamic> _batchRequest(int sample) => {
  'request_id': 'battle-load-$sample',
  'seed': sample,
  'timeout_ms': 12000,
  'max_turns': 30,
  'test_objective': 'general',
  'focus_cards': const <String>[],
  'force_focus_access_mode': 'none',
  'same_lane': false,
  'natural_sample': true,
  'deck_a': {
    'id': _ownerDeckIds[sample % _ownerCount],
    'name': 'Load A',
    'cards': const [
      {
        'name': 'Load Main',
        'set_code': 'LDT',
        'collector_number': '2',
        'quantity': 100,
        'is_commander': false,
      },
    ],
  },
  'deck_b': {
    'id': _opponentDeckId,
    'name': 'Load B',
    'cards': const [
      {
        'name': 'Load Main',
        'set_code': 'LDT',
        'collector_number': '2',
        'quantity': 100,
        'is_commander': false,
      },
    ],
  },
};

Future<void> _seed(Pool pool) async {
  for (var index = 0; index < _ownerCount; index++) {
    await pool.execute(
      Sql.named('''
        INSERT INTO users (id, username, email, password_hash)
        VALUES (
          CAST(@id AS uuid),
          @username,
          @email,
          'unused'
        )
      '''),
      parameters: {
        'id': _ownerIds[index],
        'username': 'battle_load_owner_$index',
        'email': '$_fixtureEmailPrefix$index@example.invalid',
      },
    );
  }
  await pool.execute(
    Sql.named('''
      INSERT INTO users (id, username, email, password_hash)
      VALUES (
        CAST(@id AS uuid),
        'battle_load_opponent',
        @email,
        'unused'
      )
    '''),
    parameters: {
      'id': _opponentUserId,
      'email': '${_fixtureEmailPrefix}opponent@example.invalid',
    },
  );
  await pool.execute(
    Sql.named('''
      INSERT INTO cards (
        id, scryfall_id, name, set_code, collector_number, type_line
      )
      VALUES
        (
          CAST(@commander_id AS uuid),
          CAST(@commander_scryfall_id AS uuid),
          'Load Commander',
          'LDT',
          '1',
          'Legendary Creature — Human'
        ),
        (
          CAST(@main_id AS uuid),
          CAST(@main_scryfall_id AS uuid),
          'Load Main',
          'LDT',
          '2',
          'Basic Land — Plains'
        )
    '''),
    parameters: {
      'commander_id': _commanderCardId,
      'commander_scryfall_id': _commanderScryfallId,
      'main_id': _mainCardId,
      'main_scryfall_id': _mainScryfallId,
    },
  );
  for (var index = 0; index < _ownerCount; index++) {
    await _insertDeck(
      pool,
      deckId: _ownerDeckIds[index],
      userId: _ownerIds[index],
      name: 'Battle Load Owner $index',
      isPublic: false,
    );
  }
  await _insertDeck(
    pool,
    deckId: _opponentDeckId,
    userId: _opponentUserId,
    name: 'Battle Load Opponent',
    isPublic: true,
  );
}

Future<void> _insertDeck(
  Pool pool, {
  required String deckId,
  required String userId,
  required String name,
  required bool isPublic,
}) async {
  await pool.execute(
    Sql.named('''
      INSERT INTO decks (
        id, user_id, name, format, is_public, validation_state,
        validation_reasons, validation_updated_at
      )
      VALUES (
        CAST(@deck_id AS uuid),
        CAST(@user_id AS uuid),
        @name,
        'commander',
        CAST(@is_public AS boolean),
        'validated',
        '[]'::jsonb,
        CURRENT_TIMESTAMP
      )
    '''),
    parameters: {
      'deck_id': deckId,
      'user_id': userId,
      'name': name,
      'is_public': isPublic,
    },
  );
  await pool.execute(
    Sql.named('''
      INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander)
      VALUES
        (CAST(@deck_id AS uuid), CAST(@commander_id AS uuid), 1, TRUE),
        (CAST(@deck_id AS uuid), CAST(@main_id AS uuid), 99, FALSE)
    '''),
    parameters: {
      'deck_id': deckId,
      'commander_id': _commanderCardId,
      'main_id': _mainCardId,
    },
  );
  await pool.execute(
    Sql.named('''
      UPDATE decks
      SET validation_state = 'validated',
          validation_reasons = '[]'::jsonb,
          validation_updated_at = CURRENT_TIMESTAMP
      WHERE id = CAST(@deck_id AS uuid)
    '''),
    parameters: {'deck_id': deckId},
  );
}

Future<void> _cleanup(Pool pool) async {
  await pool.execute(
    "DELETE FROM users WHERE email LIKE '${_fixtureEmailPrefix}%'",
  );
  await pool.execute(
    Sql.named('''
      DELETE FROM cards
      WHERE id IN (CAST(@commander_id AS uuid), CAST(@main_id AS uuid))
    '''),
    parameters: {'commander_id': _commanderCardId, 'main_id': _mainCardId},
  );
}

String _uuid(int value) =>
    '70000000-0000-4000-8000-${value.toString().padLeft(12, '0')}';
