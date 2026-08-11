import 'dart:io';

import 'package:server/battle/interactive_battle_metrics_service.dart';
import 'package:test/test.dart';

void main() {
  test('builds a closed redacted Battle Coach operational snapshot', () {
    final snapshot = InteractiveBattleMetricsService.snapshotFromRow({
      'active_total': 5,
      'waiting_for_action': 3,
      'waiting_past_prompt_deadline': 2,
      'ttl_expired_non_terminal': 1,
      'max_active_age_seconds': '701',
      'max_prompt_overdue_seconds': 41,
      'terminal_total': 12,
      'terminal_completed': 4,
      'terminal_censored': 1,
      'terminal_conceded': 2,
      'terminal_expired': 1,
      'terminal_timeout': 1,
      'terminal_abandoned': 0,
      'terminal_engine_error': 1,
      'terminal_process_lost': 1,
      'terminal_persistence_error': 1,
      'user_id': 'must-not-leak',
      'deck_a_id': 'must-not-leak',
      'session_id': 'must-not-leak',
      'prompt_id': 'must-not-leak',
      'card_name': 'must-not-leak',
    });

    expect(snapshot['schema_version'], interactiveBattleMetricsSchemaVersion);
    expect(snapshot['status'], 'ok');
    expect(snapshot['window_hours'], 24);
    expect(snapshot['active'], {
      'total': 5,
      'waiting_for_action': 3,
      'waiting_past_prompt_deadline': 2,
      'ttl_expired_non_terminal': 1,
      'max_age_seconds': 701,
      'max_prompt_overdue_seconds': 41,
    });
    expect(snapshot['terminals_24h'], {
      'total': 12,
      'completed': 4,
      'censored': 1,
      'conceded': 2,
      'expired': 1,
      'timeout': 1,
      'abandoned': 0,
      'engine_error': 1,
      'process_lost': 1,
      'persistence_error': 1,
    });
    for (final forbidden in const [
      'user_id',
      'deck_a_id',
      'session_id',
      'prompt_id',
      'card_name',
      'must-not-leak',
    ]) {
      expect(snapshot.toString(), isNot(contains(forbidden)));
    }
  });

  test('query and dashboard expose only aggregate Coach health', () {
    final sql = InteractiveBattleMetricsService.aggregateSql;
    final dashboard =
        File('routes/health/dashboard/index.dart').readAsStringSync();

    expect(sql, contains("status = 'waiting_for_action'"));
    expect(sql, contains('prompt_deadline_at <= CURRENT_TIMESTAMP'));
    expect(sql, contains('expires_at <= CURRENT_TIMESTAMP'));
    expect(sql, contains("status = 'process_lost'"));
    expect(sql, contains("status = 'timeout'"));
    expect(sql, contains("status = 'persistence_error'"));
    expect(sql, contains("finished_at >= NOW() - INTERVAL '24 hours'"));
    for (final forbiddenProjection in const [
      'user_id',
      'deck_a_id',
      'deck_b_id',
      'active_prompt',
      'private_state',
      'request_payload',
      'replay_id',
    ]) {
      expect(sql, isNot(contains(forbiddenProjection)));
    }
    expect(
      dashboard,
      contains('InteractiveBattleMetricsService(pool).snapshot()'),
    );
    expect(dashboard, contains("'interactive_battle': interactiveBattle"));
    expect(dashboard, contains('interactiveBattle: interactiveBattle'));
  });

  test('not initialized response remains aggregate and fail closed', () {
    expect(InteractiveBattleMetricsService.notInitialized(), {
      'schema_version': interactiveBattleMetricsSchemaVersion,
      'status': 'not_initialized',
      'window_hours': interactiveBattleMetricsWindowHours,
    });
  });
}
