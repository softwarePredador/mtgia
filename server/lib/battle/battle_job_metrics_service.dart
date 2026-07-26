import 'package:postgres/postgres.dart';

const battleJobMetricsSchemaVersion = 'battle_job_metrics_v1';

/// Returns only aggregate operational data. No user, deck, request, lease,
/// replay, process or card identifier is projected.
final class BattleJobMetricsService {
  const BattleJobMetricsService(this._pool);

  final Pool _pool;

  static int normalizeWindowHours(int value) => value.clamp(1, 168);

  Future<Map<String, dynamic>> snapshot({int windowHours = 24}) async {
    final boundedWindow = normalizeWindowHours(windowHours);
    final availability = await _pool.execute('''
      SELECT
        to_regclass('public.battle_jobs') IS NOT NULL AS jobs_ready,
        to_regclass('public.battle_simulation_attempts') IS NOT NULL
          AS attempts_ready
    ''');
    final availabilityRow = availability.first.toColumnMap();
    if (availabilityRow['jobs_ready'] != true ||
        availabilityRow['attempts_ready'] != true) {
      return notInitialized(windowHours: boundedWindow);
    }

    final result = await _pool.execute(
      Sql.named(_aggregateSql),
      parameters: {'windowHours': boundedWindow},
    );
    return snapshotFromRow(
      result.first.toColumnMap(),
      windowHours: boundedWindow,
    );
  }

  static Map<String, dynamic> notInitialized({required int windowHours}) => {
    'schema_version': battleJobMetricsSchemaVersion,
    'status': 'not_initialized',
    'window_hours': normalizeWindowHours(windowHours),
  };

  static Map<String, dynamic> snapshotFromRow(
    Map<String, dynamic> row, {
    required int windowHours,
  }) {
    int integer(String key) => _number(row[key]).round();
    double decimal(String key) =>
        double.parse(_number(row[key]).toStringAsFixed(2));

    return {
      'schema_version': battleJobMetricsSchemaVersion,
      'status': 'ok',
      'window_hours': normalizeWindowHours(windowHours),
      'jobs': {
        'created': integer('jobs_created'),
        'active': integer('jobs_active'),
        'completed': integer('jobs_completed'),
        'censored': integer('jobs_censored'),
        'timeout': integer('jobs_timeout'),
        'coverage_error': integer('jobs_coverage_error'),
        'engine_error': integer('jobs_engine_error'),
        'cancelled': integer('jobs_cancelled'),
        'persistence_error': integer('jobs_persistence_error'),
      },
      'queue': {
        'depth': integer('queue_depth'),
        'oldest_wait_seconds': integer('oldest_queue_wait_seconds'),
        'wait_avg_ms': decimal('queue_wait_avg_ms'),
        'wait_p95_ms': decimal('queue_wait_p95_ms'),
      },
      'execution': {
        'attempts': integer('attempts_total'),
        'duration_avg_ms': decimal('duration_avg_ms'),
        'duration_p95_ms': decimal('duration_p95_ms'),
      },
      'payload': {
        'request_avg_bytes': decimal('payload_avg_bytes'),
        'request_p95_bytes': decimal('payload_p95_bytes'),
        'request_max_bytes': integer('payload_max_bytes'),
      },
      'truncation': {
        'events': integer('events_truncated'),
        'snapshots': integer('snapshots_truncated'),
        'any': integer('any_truncated'),
      },
      'fallback': {
        'total': integer('fallback_total'),
        'forge': integer('fallback_forge'),
        'native': integer('fallback_native'),
      },
      'persistence': {'failures': integer('persistence_failures')},
    };
  }

  static const String aggregateSql = _aggregateSql;
}

num _number(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

const _aggregateSql = r'''
  WITH scoped_jobs AS (
    SELECT *
    FROM battle_jobs
    WHERE created_at >= NOW() - (@windowHours * INTERVAL '1 hour')
  ),
  scoped_attempts AS (
    SELECT *
    FROM battle_simulation_attempts
    WHERE started_at >= NOW() - (@windowHours * INTERVAL '1 hour')
  )
  SELECT
    (SELECT COUNT(*)::int FROM scoped_jobs) AS jobs_created,
    (
      SELECT COUNT(*)::int
      FROM battle_jobs
      WHERE status IN ('queued', 'claimed', 'running', 'cancel_pending')
    ) AS jobs_active,
    (SELECT COUNT(*)::int FROM scoped_jobs WHERE status = 'completed')
      AS jobs_completed,
    (SELECT COUNT(*)::int FROM scoped_jobs WHERE status = 'censored')
      AS jobs_censored,
    (SELECT COUNT(*)::int FROM scoped_jobs WHERE status = 'timeout')
      AS jobs_timeout,
    (SELECT COUNT(*)::int FROM scoped_jobs WHERE status = 'coverage_error')
      AS jobs_coverage_error,
    (SELECT COUNT(*)::int FROM scoped_jobs WHERE status = 'engine_error')
      AS jobs_engine_error,
    (SELECT COUNT(*)::int FROM scoped_jobs WHERE status = 'cancelled')
      AS jobs_cancelled,
    (SELECT COUNT(*)::int FROM scoped_jobs WHERE status = 'persistence_error')
      AS jobs_persistence_error,
    (
      SELECT COUNT(*)::int FROM battle_jobs WHERE status = 'queued'
    ) AS queue_depth,
    COALESCE((
      SELECT EXTRACT(EPOCH FROM (NOW() - MIN(created_at)))::int
      FROM battle_jobs WHERE status = 'queued'
    ), 0) AS oldest_queue_wait_seconds,
    COALESCE((
      SELECT AVG(EXTRACT(EPOCH FROM (claimed_at - created_at)) * 1000)
      FROM scoped_jobs WHERE claimed_at IS NOT NULL
    ), 0) AS queue_wait_avg_ms,
    COALESCE((
      SELECT percentile_cont(0.95) WITHIN GROUP (
        ORDER BY EXTRACT(EPOCH FROM (claimed_at - created_at)) * 1000
      )
      FROM scoped_jobs WHERE claimed_at IS NOT NULL
    ), 0) AS queue_wait_p95_ms,
    (SELECT COUNT(*)::int FROM scoped_attempts) AS attempts_total,
    COALESCE((
      SELECT AVG(EXTRACT(EPOCH FROM (finished_at - started_at)) * 1000)
      FROM scoped_attempts WHERE finished_at IS NOT NULL
    ), 0) AS duration_avg_ms,
    COALESCE((
      SELECT percentile_cont(0.95) WITHIN GROUP (
        ORDER BY EXTRACT(EPOCH FROM (finished_at - started_at)) * 1000
      )
      FROM scoped_attempts WHERE finished_at IS NOT NULL
    ), 0) AS duration_p95_ms,
    COALESCE((
      SELECT AVG(octet_length(request_payload::text))
      FROM scoped_jobs
    ), 0) AS payload_avg_bytes,
    COALESCE((
      SELECT percentile_cont(0.95) WITHIN GROUP (
        ORDER BY octet_length(request_payload::text)
      )
      FROM scoped_jobs
    ), 0) AS payload_p95_bytes,
    COALESCE((
      SELECT MAX(octet_length(request_payload::text))
      FROM scoped_jobs
    ), 0) AS payload_max_bytes,
    (
      SELECT COUNT(*)::int FROM scoped_attempts
      WHERE events_truncated
    ) AS events_truncated,
    (
      SELECT COUNT(*)::int FROM scoped_attempts
      WHERE snapshots_truncated
    ) AS snapshots_truncated,
    (
      SELECT COUNT(*)::int FROM scoped_attempts
      WHERE events_truncated OR snapshots_truncated
    ) AS any_truncated,
    (
      SELECT COUNT(*)::int FROM scoped_jobs
      WHERE requested_engine = 'auto' AND engine IN ('forge', 'native')
    ) AS fallback_total,
    (
      SELECT COUNT(*)::int FROM scoped_jobs
      WHERE requested_engine = 'auto' AND engine = 'forge'
    ) AS fallback_forge,
    (
      SELECT COUNT(*)::int FROM scoped_jobs
      WHERE requested_engine = 'auto' AND engine = 'native'
    ) AS fallback_native,
    (
      SELECT
        (
          COUNT(*) FILTER (WHERE status = 'persistence_error') +
          (
            SELECT COUNT(*) FROM scoped_attempts
            WHERE outcome = 'persistence_error'
              AND job_request_hash IS NULL
          )
        )::int
      FROM scoped_jobs
    ) AS persistence_failures
''';
