import 'dart:io';

import 'package:server/battle/battle_job_metrics_service.dart';
import 'package:test/test.dart';

void main() {
  test('normalizes the bounded operational window', () {
    expect(BattleJobMetricsService.normalizeWindowHours(-1), 1);
    expect(BattleJobMetricsService.normalizeWindowHours(24), 24);
    expect(BattleJobMetricsService.normalizeWindowHours(999), 168);
  });

  test('builds a redacted closed aggregate snapshot', () {
    final snapshot = BattleJobMetricsService.snapshotFromRow({
      'jobs_created': 9,
      'jobs_active': 2,
      'jobs_completed': 4,
      'jobs_censored': 1,
      'jobs_timeout': 1,
      'jobs_coverage_error': 1,
      'jobs_engine_error': 1,
      'jobs_cancelled': 0,
      'jobs_persistence_error': 1,
      'queue_depth': 2,
      'oldest_queue_wait_seconds': 7,
      'queue_wait_avg_ms': '12.345',
      'queue_wait_p95_ms': 23.456,
      'attempts_total': 8,
      'duration_avg_ms': 1250.555,
      'duration_p95_ms': '2000.999',
      'payload_avg_bytes': 512.25,
      'payload_p95_bytes': 900,
      'payload_max_bytes': 1024,
      'events_truncated': 1,
      'snapshots_truncated': 2,
      'any_truncated': 2,
      'fallback_total': 3,
      'fallback_forge': 2,
      'fallback_native': 1,
      'persistence_failures': 1,
      'user_id': 'must-not-leak',
      'deck_a_id': 'must-not-leak',
      'request_hash': 'must-not-leak',
    }, windowHours: 24);

    expect(snapshot['schema_version'], battleJobMetricsSchemaVersion);
    expect(snapshot['status'], 'ok');
    expect(snapshot['queue'], {
      'depth': 2,
      'oldest_wait_seconds': 7,
      'wait_avg_ms': 12.35,
      'wait_p95_ms': 23.46,
    });
    expect(snapshot['execution'], {
      'attempts': 8,
      'duration_avg_ms': 1250.56,
      'duration_p95_ms': 2001.0,
    });
    expect(snapshot['payload'], {
      'request_avg_bytes': 512.25,
      'request_p95_bytes': 900.0,
      'request_max_bytes': 1024,
    });
    expect(snapshot['truncation'], {'events': 1, 'snapshots': 2, 'any': 2});
    expect(snapshot['fallback'], {'total': 3, 'forge': 2, 'native': 1});
    expect(snapshot['persistence'], {'failures': 1});
    expect(snapshot, isNot(contains('user_id')));
    expect(snapshot.toString(), isNot(contains('must-not-leak')));
  });

  test('query and protected dashboard cover the BL5 metric matrix', () {
    final sql = BattleJobMetricsService.aggregateSql;
    final dashboard =
        File('routes/health/dashboard/index.dart').readAsStringSync();

    expect(sql, contains('queue_wait_p95_ms'));
    expect(sql, contains('duration_p95_ms'));
    expect(sql, contains('octet_length(request_payload::text)'));
    expect(sql, contains('events_truncated OR snapshots_truncated'));
    expect(sql, contains("requested_engine = 'auto'"));
    expect(sql, contains("status = 'persistence_error'"));
    expect(dashboard, contains('BattleJobMetricsService(pool).snapshot()'));
    expect(dashboard, contains("'battle_jobs': battleJobs"));
  });
}
