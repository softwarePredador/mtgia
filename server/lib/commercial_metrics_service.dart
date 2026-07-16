import 'package:postgres/postgres.dart';

class CommercialMetricsService {
  const CommercialMetricsService(this.pool);

  final Pool pool;

  Future<Map<String, dynamic>> snapshot({int days = 30}) async {
    final safeDays = normalizeWindowDays(days);
    final hasActivation = await _tableExists('activation_funnel_events');
    final hasAiLogs = await _tableExists('ai_logs');
    final hasUserPlans = await _tableExists('user_plans');
    final hasReports = await _tableExists('shared_deck_reports');
    final hasPostGame = await _tableExists('post_game_notes');

    final activation =
        hasActivation
            ? await _activationFunnel(safeDays)
            : _missing('activation_funnel_events');
    final ai = hasAiLogs ? await _aiPerformance(safeDays) : _missing('ai_logs');
    final plans = hasUserPlans ? await _planMix() : _missing('user_plans');
    final reports =
        hasReports
            ? await _sharedReports(safeDays)
            : _missing('shared_deck_reports');
    final retention =
        hasPostGame ? await _retention(safeDays) : _missing('post_game_notes');

    return {
      'status': 'ok',
      'window_days': safeDays,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'activation_funnel': activation,
      'ai_performance': ai,
      'ai_performance_history':
          hasAiLogs
              ? await aiPerformanceHistory(days: safeDays, bucket: 'day')
              : _missing('ai_logs'),
      'plan_mix': plans,
      'shareable_reports': reports,
      'retention': retention,
    };
  }

  static int normalizeWindowDays(int days) => days.clamp(1, 90);
  static int countAiActivationEvents(Map<String, int> events) =>
      (events['deck_generated'] ?? 0) +
      (events['deck_optimized'] ?? 0) +
      (events['deck_rebuild_created'] ?? 0);

  static String normalizeHistoryBucket(String? bucket) {
    final normalized = bucket?.trim().toLowerCase();
    return normalized == 'hour' ? 'hour' : 'day';
  }

  static int normalizeHistoryWindowDays(int days, {String bucket = 'day'}) {
    final normalizedBucket = normalizeHistoryBucket(bucket);
    final maxDays = normalizedBucket == 'hour' ? 7 : 90;
    return days.clamp(1, maxDays);
  }

  Future<Map<String, dynamic>> aiPerformanceHistory({
    int days = 30,
    String bucket = 'day',
  }) async {
    final normalizedBucket = normalizeHistoryBucket(bucket);
    final safeDays = normalizeHistoryWindowDays(days, bucket: normalizedBucket);
    final hasAiLogs = await _tableExists('ai_logs');
    if (!hasAiLogs) return _missing('ai_logs');

    final result = await pool.execute(
      Sql.named('''
        SELECT
          date_trunc('$normalizedBucket', created_at) AS period_start,
          endpoint,
          COUNT(*)::int AS request_count,
          SUM(CASE WHEN success THEN 0 ELSE 1 END)::int AS error_count,
          ROUND(AVG(latency_ms))::int AS avg_latency_ms,
          COALESCE(
            percentile_disc(0.95) WITHIN GROUP (ORDER BY latency_ms),
            0
          )::int AS p95_latency_ms,
          COALESCE(SUM(COALESCE(input_tokens, 0)), 0)::int AS input_tokens,
          COALESCE(SUM(COALESCE(output_tokens, 0)), 0)::int AS output_tokens
        FROM ai_logs
        WHERE created_at >= NOW() - (@days * INTERVAL '1 day')
        GROUP BY period_start, endpoint
        ORDER BY period_start ASC, endpoint ASC
      '''),
      parameters: {'days': safeDays},
    );

    final periodsByStart = <String, Map<String, dynamic>>{};
    var totalRequests = 0;
    var totalErrors = 0;
    var totalInputTokens = 0;
    var totalOutputTokens = 0;

    for (final row in result) {
      final periodStart = _dateIso(row[0]);
      final endpoint = row[1]?.toString() ?? 'unknown';
      final requestCount = (row[2] as int?) ?? 0;
      final errorCount = (row[3] as int?) ?? 0;
      final inputTokens = (row[6] as int?) ?? 0;
      final outputTokens = (row[7] as int?) ?? 0;

      totalRequests += requestCount;
      totalErrors += errorCount;
      totalInputTokens += inputTokens;
      totalOutputTokens += outputTokens;

      final period = periodsByStart.putIfAbsent(
        periodStart,
        () => {
          'period_start': periodStart,
          'request_count': 0,
          'error_count': 0,
          'total_tokens': 0,
          'endpoints': <Map<String, dynamic>>[],
        },
      );
      period['request_count'] = (period['request_count'] as int) + requestCount;
      period['error_count'] = (period['error_count'] as int) + errorCount;
      period['total_tokens'] =
          (period['total_tokens'] as int) + inputTokens + outputTokens;
      (period['endpoints'] as List<Map<String, dynamic>>).add({
        'endpoint': endpoint,
        'request_count': requestCount,
        'error_count': errorCount,
        'error_rate': requestCount > 0 ? _ratio(errorCount, requestCount) : 0.0,
        'avg_latency_ms': (row[4] as int?) ?? 0,
        'p95_latency_ms': (row[5] as int?) ?? 0,
        'input_tokens': inputTokens,
        'output_tokens': outputTokens,
      });
    }

    final periods =
        periodsByStart.values.map((period) {
          final requestCount = period['request_count'] as int;
          final errorCount = period['error_count'] as int;
          return {
            ...period,
            'error_rate':
                requestCount > 0 ? _ratio(errorCount, requestCount) : 0.0,
          };
        }).toList();

    return {
      'status': 'ok',
      'bucket': normalizedBucket,
      'window_days': safeDays,
      'period_count': periods.length,
      'totals': {
        'request_count': totalRequests,
        'error_count': totalErrors,
        'error_rate':
            totalRequests > 0 ? _ratio(totalErrors, totalRequests) : 0.0,
        'input_tokens': totalInputTokens,
        'output_tokens': totalOutputTokens,
        'total_tokens': totalInputTokens + totalOutputTokens,
      },
      'periods': periods,
    };
  }

  Map<String, dynamic> _missing(String table) => {
    'status': 'not_initialized',
    'table': table,
  };

  Future<Map<String, dynamic>> _activationFunnel(int days) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT event_name, COUNT(*)::int AS total
        FROM activation_funnel_events
        WHERE created_at >= NOW() - (@days * INTERVAL '1 day')
        GROUP BY event_name
        ORDER BY event_name ASC
      '''),
      parameters: {'days': days},
    );

    final events = <String, int>{};
    for (final row in result) {
      events[row[0].toString()] = (row[1] as int?) ?? 0;
    }

    final signups = await _countUsers(days);
    final deckCreated = events['deck_created'] ?? 0;
    final aiUsed = countAiActivationEvents(events);

    return {
      'status': 'ok',
      'signups': signups,
      'events': events,
      'deck_created_count': deckCreated,
      'deck_generated_count': events['deck_generated'] ?? 0,
      'ai_used_count': aiUsed,
      'deck_created_per_signup':
          signups > 0 ? _ratio(deckCreated, signups) : 0.0,
      'ai_used_per_signup': signups > 0 ? _ratio(aiUsed, signups) : 0.0,
    };
  }

  Future<Map<String, dynamic>> _aiPerformance(int days) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT
          endpoint,
          COUNT(*)::int AS request_count,
          SUM(CASE WHEN success THEN 0 ELSE 1 END)::int AS error_count,
          ROUND(AVG(latency_ms))::int AS avg_latency_ms,
          COALESCE(
            percentile_disc(0.95) WITHIN GROUP (ORDER BY latency_ms),
            0
          )::int AS p95_latency_ms,
          COALESCE(SUM(COALESCE(input_tokens, 0)), 0)::int AS input_tokens,
          COALESCE(SUM(COALESCE(output_tokens, 0)), 0)::int AS output_tokens
        FROM ai_logs
        WHERE created_at >= NOW() - (@days * INTERVAL '1 day')
        GROUP BY endpoint
        ORDER BY request_count DESC, endpoint ASC
      '''),
      parameters: {'days': days},
    );

    var totalRequests = 0;
    var totalErrors = 0;
    var totalTokens = 0;
    final endpoints = <Map<String, dynamic>>[];

    for (final row in result) {
      final requestCount = (row[1] as int?) ?? 0;
      final errorCount = (row[2] as int?) ?? 0;
      final inputTokens = (row[5] as int?) ?? 0;
      final outputTokens = (row[6] as int?) ?? 0;
      totalRequests += requestCount;
      totalErrors += errorCount;
      totalTokens += inputTokens + outputTokens;
      endpoints.add({
        'endpoint': row[0],
        'request_count': requestCount,
        'error_count': errorCount,
        'error_rate': requestCount > 0 ? _ratio(errorCount, requestCount) : 0.0,
        'avg_latency_ms': (row[3] as int?) ?? 0,
        'p95_latency_ms': (row[4] as int?) ?? 0,
        'input_tokens': inputTokens,
        'output_tokens': outputTokens,
      });
    }

    return {
      'status': 'ok',
      'request_count': totalRequests,
      'error_count': totalErrors,
      'error_rate':
          totalRequests > 0 ? _ratio(totalErrors, totalRequests) : 0.0,
      'total_tokens': totalTokens,
      'endpoints': endpoints,
    };
  }

  Future<Map<String, dynamic>> _planMix() async {
    final result = await pool.execute(
      Sql.named('''
      SELECT plan_name, status, COUNT(*)::int AS total
      FROM user_plans
      GROUP BY plan_name, status
      ORDER BY plan_name ASC, status ASC
    '''),
    );

    final rows = <Map<String, dynamic>>[];
    var total = 0;
    for (final row in result) {
      final count = (row[2] as int?) ?? 0;
      total += count;
      rows.add({'plan_name': row[0], 'status': row[1], 'count': count});
    }

    return {'status': 'ok', 'total_users_with_plan': total, 'plans': rows};
  }

  Future<Map<String, dynamic>> _sharedReports(int days) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT
          COUNT(*)::int AS total,
          COUNT(*) FILTER (WHERE is_public)::int AS public_total
        FROM shared_deck_reports
        WHERE created_at >= NOW() - (@days * INTERVAL '1 day')
      '''),
      parameters: {'days': days},
    );

    final row = result.first;
    return {
      'status': 'ok',
      'created_count': (row[0] as int?) ?? 0,
      'public_count': (row[1] as int?) ?? 0,
    };
  }

  Future<Map<String, dynamic>> _retention(int days) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT
          COUNT(*)::int AS note_count,
          COUNT(DISTINCT user_id)::int AS active_users,
          COUNT(DISTINCT deck_id)::int AS active_decks
        FROM post_game_notes
        WHERE created_at >= NOW() - (@days * INTERVAL '1 day')
      '''),
      parameters: {'days': days},
    );

    final row = result.first;
    return {
      'status': 'ok',
      'post_game_note_count': (row[0] as int?) ?? 0,
      'active_users': (row[1] as int?) ?? 0,
      'active_decks': (row[2] as int?) ?? 0,
    };
  }

  Future<int> _countUsers(int days) async {
    final hasUsers = await _tableExists('users');
    if (!hasUsers) return 0;

    final hasCreatedAt = await _columnExists('users', 'created_at');
    if (!hasCreatedAt) return 0;

    final result = await pool.execute(
      Sql.named('''
        SELECT COUNT(*)::int
        FROM users
        WHERE created_at >= NOW() - (@days * INTERVAL '1 day')
      '''),
      parameters: {'days': days},
    );
    return result.isEmpty ? 0 : ((result.first[0] as int?) ?? 0);
  }

  Future<bool> _tableExists(String table) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT COUNT(*)::int AS c
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name = @table
      '''),
      parameters: {'table': table},
    );
    return result.isNotEmpty && (((result.first[0] as int?) ?? 0) > 0);
  }

  Future<bool> _columnExists(String table, String column) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT COUNT(*)::int AS c
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = @table
          AND column_name = @column
      '''),
      parameters: {'table': table, 'column': column},
    );
    return result.isNotEmpty && (((result.first[0] as int?) ?? 0) > 0);
  }
}

String _dateIso(Object? value) {
  if (value is DateTime) return value.toUtc().toIso8601String();
  return DateTime.tryParse(
        value?.toString() ?? '',
      )?.toUtc().toIso8601String() ??
      value.toString();
}

double _ratio(int numerator, int denominator) =>
    double.parse((numerator / denominator).toStringAsFixed(4));
