import 'package:postgres/postgres.dart';

const interactiveBattleMetricsSchemaVersion = 'interactive_battle_metrics_v1';
const interactiveBattleMetricsWindowHours = 24;

/// Returns aggregate Battle Coach health only. User, deck, session, prompt,
/// request, process, replay and card identifiers are never projected.
final class InteractiveBattleMetricsService {
  const InteractiveBattleMetricsService(this._pool);

  final Pool _pool;

  Future<Map<String, dynamic>> snapshot() async {
    final availability = await _pool.execute('''
      SELECT
        to_regclass('public.interactive_battle_sessions') IS NOT NULL
          AS sessions_ready
    ''');
    if (availability.isEmpty ||
        availability.first.toColumnMap()['sessions_ready'] != true) {
      return notInitialized();
    }

    final result = await _pool.execute(_aggregateSql);
    return snapshotFromRow(result.first.toColumnMap());
  }

  static Map<String, dynamic> notInitialized() => const {
    'schema_version': interactiveBattleMetricsSchemaVersion,
    'status': 'not_initialized',
    'window_hours': interactiveBattleMetricsWindowHours,
  };

  static Map<String, dynamic> snapshotFromRow(Map<String, dynamic> row) {
    int integer(String key) => _number(row[key]).round();

    return {
      'schema_version': interactiveBattleMetricsSchemaVersion,
      'status': 'ok',
      'window_hours': interactiveBattleMetricsWindowHours,
      'active': {
        'total': integer('active_total'),
        'waiting_for_action': integer('waiting_for_action'),
        'waiting_past_prompt_deadline': integer('waiting_past_prompt_deadline'),
        'ttl_expired_non_terminal': integer('ttl_expired_non_terminal'),
        'max_age_seconds': integer('max_active_age_seconds'),
        'max_prompt_overdue_seconds': integer('max_prompt_overdue_seconds'),
      },
      'terminals_24h': {
        'total': integer('terminal_total'),
        'completed': integer('terminal_completed'),
        'censored': integer('terminal_censored'),
        'conceded': integer('terminal_conceded'),
        'expired': integer('terminal_expired'),
        'timeout': integer('terminal_timeout'),
        'abandoned': integer('terminal_abandoned'),
        'engine_error': integer('terminal_engine_error'),
        'process_lost': integer('terminal_process_lost'),
        'persistence_error': integer('terminal_persistence_error'),
      },
    };
  }

  static const String aggregateSql = _aggregateSql;
}

num _number(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

const _aggregateSql = r'''
  WITH active_sessions AS MATERIALIZED (
    SELECT status, created_at, expires_at, prompt_deadline_at
    FROM interactive_battle_sessions
    WHERE status IN (
      'starting',
      'running',
      'waiting_for_action',
      'action_pending'
    )
  ),
  recent_terminals AS MATERIALIZED (
    SELECT status
    FROM interactive_battle_sessions
    WHERE status IN (
      'completed',
      'censored',
      'conceded',
      'expired',
      'timeout',
      'abandoned',
      'engine_error',
      'process_lost',
      'persistence_error'
    )
      AND finished_at >= NOW() - INTERVAL '24 hours'
  )
  SELECT
    (SELECT COUNT(*)::int FROM active_sessions) AS active_total,
    (
      SELECT COUNT(*)::int
      FROM active_sessions
      WHERE status = 'waiting_for_action'
    ) AS waiting_for_action,
    (
      SELECT COUNT(*)::int
      FROM active_sessions
      WHERE status = 'waiting_for_action'
        AND prompt_deadline_at <= CURRENT_TIMESTAMP
    ) AS waiting_past_prompt_deadline,
    (
      SELECT COUNT(*)::int
      FROM active_sessions
      WHERE expires_at <= CURRENT_TIMESTAMP
    ) AS ttl_expired_non_terminal,
    COALESCE((
      SELECT EXTRACT(EPOCH FROM (NOW() - MIN(created_at)))::int
      FROM active_sessions
    ), 0) AS max_active_age_seconds,
    COALESCE((
      SELECT EXTRACT(EPOCH FROM (NOW() - MIN(prompt_deadline_at)))::int
      FROM active_sessions
      WHERE status = 'waiting_for_action'
        AND prompt_deadline_at <= CURRENT_TIMESTAMP
    ), 0) AS max_prompt_overdue_seconds,
    (SELECT COUNT(*)::int FROM recent_terminals) AS terminal_total,
    (
      SELECT COUNT(*)::int FROM recent_terminals WHERE status = 'completed'
    ) AS terminal_completed,
    (
      SELECT COUNT(*)::int FROM recent_terminals WHERE status = 'censored'
    ) AS terminal_censored,
    (
      SELECT COUNT(*)::int FROM recent_terminals WHERE status = 'conceded'
    ) AS terminal_conceded,
    (
      SELECT COUNT(*)::int FROM recent_terminals WHERE status = 'expired'
    ) AS terminal_expired,
    (
      SELECT COUNT(*)::int FROM recent_terminals WHERE status = 'timeout'
    ) AS terminal_timeout,
    (
      SELECT COUNT(*)::int FROM recent_terminals WHERE status = 'abandoned'
    ) AS terminal_abandoned,
    (
      SELECT COUNT(*)::int FROM recent_terminals WHERE status = 'engine_error'
    ) AS terminal_engine_error,
    (
      SELECT COUNT(*)::int FROM recent_terminals WHERE status = 'process_lost'
    ) AS terminal_process_lost,
    (
      SELECT COUNT(*)::int
      FROM recent_terminals
      WHERE status = 'persistence_error'
    ) AS terminal_persistence_error
''';
